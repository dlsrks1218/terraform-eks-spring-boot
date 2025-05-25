module "eks" {
  source  = "terraform-aws-modules/eks/aws"
  version = "~> 20.0"

  cluster_name                         = var.cluster_name
  cluster_version                      = var.cluster_version
  vpc_id                               = module.vpc.vpc_id
  subnet_ids                           = module.vpc.private_subnets
  cluster_endpoint_public_access       = var.endpoint_public_access
  cluster_endpoint_private_access      = var.endpoint_private_access
  cluster_endpoint_public_access_cidrs = ["0.0.0.0/0"] # 필요 시 퍼블릭 액세스 위한 cidr 구성
  cluster_enabled_log_types = [
    "api",           # API 서버
    "audit",         # 감사 로그
    "authenticator", # 인증(Authenticator) 로그
  ]
  cloudwatch_log_group_retention_in_days = 7

  # EKS 애드온
  cluster_addons = { # addon_version 명시하지 않으면 plan 시점 최신 버전으로 설치 혹은 업데이트
    coredns = {      # 클러스터 내 DNS 해석(서비스 이름)-> Cluster IP, 파드 이름 -> IP)
      resolve_conflicts = "OVERWRITE"
    }
    eks-pod-identity-agent = { # IRSA를 위한 에이전트(IAM Roles for Service Accounts)
      # 파드마다 서비스 어카운트에 IAM 역할을 연결해서, sts:AssumeRoleWithWebIdentity 방식으로 AWS API 호출 권한을 세분화
      resolve_conflicts = "OVERWRITE"
    }
    kube-proxy = { # 각 노드에서 iptables 기반으로  서비스 vip에서 실제 파드 IP로 트래픽 프록시 혹은 로드밸런싱
      resolve_conflicts = "OVERWRITE"
    }
    vpc-cni = { # 파드에 VPC 서브넷 Ip를 바로 할당해주는 네트워크 플러그인
      resolve_conflicts = "OVERWRITE"
    }
  }

  authentication_mode                      = "API_AND_CONFIG_MAP" # API와 ConfigMap 방식을 병행
  enable_cluster_creator_admin_permissions = false                # false로 해야 중복 Entry 생성 안 함
  access_entries = merge(
    # 1) 관리자 역할 - AmazonEKSClusterAdminPolicy
    {
      for name, arn in local.rbac_admin_users : name => {
        principal_arn    = arn
        kubernetes_group = ["system:masters"]
        policy_associations = {
          admin = {
            policy_arn   = "arn:aws:eks::aws:cluster-access-policy/AmazonEKSClusterAdminPolicy"
            access_scope = { type = "cluster", namespaces = [] } # 전체 namespace 접근
          }
        }
      }
    }
    ,
    # 2) 개발자 역할 - AmazonEKSViewPolicy
    {
      for name, arn in local.rbac_developer_users : name => {
        principal_arn    = arn
        kubernetes_group = ["system:master"]
        policy_associations = {
          view = {
            policy_arn   = "arn:aws:eks::aws:cluster-access-policy/AmazonEKSViewPolicy"
            access_scope = { type = "namespace", namespaces = ["default"] } # 워크로드를 배포할 namespace만 접근
          }
        }
      }
    }
  )

  # EKS 관리형 노드 그룹
  eks_managed_node_groups = {
    workload = {
      ami_type       = "AL2023_x86_64_STANDARD"
      desired_size   = 2
      max_size       = 4
      min_size       = 2
      instance_types = ["t3.medium"]
      capacity_type  = "ON_DEMAND" # SPOT
      subnet_ids     = module.vpc.private_subnets

      labels = {
        role        = "workload"
        subnet-type = "private"
      }
      # taints = []
      tags = {
        "k8s.io/cluster-autoscaler/enabled"             = "true" # 
        "k8s.io/cluster-autoscaler/${var.cluster_name}" = "owned"
      }
    }
  }

  enable_irsa = true

  tags = merge(
    local.tags,
    {
      Item = "EKS"
    }
  )

  depends_on = [module.vpc] # vpc 생성 이후에 eks 생성하도록 의존성 추가
}

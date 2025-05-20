provider "aws" {
  region = var.aws_region
}

locals {
  tags = merge(
    {
      Item        = ""
      Solution    = var.solution_name
      Alias       = "-"
      Environment = var.environment
      Terraform   = var.terraform
    },
    var.additional_tags
  )

  ## Access Entries를 활용하여 EKS 접근 제어, Multi-Account 계정 환경에서의 assumeRole 활용한 접근
  ## Multi Account 환경이 아니라면 EKS에 접근할 IAM 사용자를 필요한 권한에 맞게 추가 필요 
  # EKS 클러스터에 Admin 권한으로 접근
  rbac_admin_users = {
    admin_role  = "arn:aws:iam::${var.account_id}:role/cross-account-admin-role" # 관리자 역할을 가정하여 접근
    mgmt_role   = "arn:aws:iam::${var.account_id}:role/cross-account-mgmt-role"  # ci/cd 도구나 별도의 관리 도구를 위한 역할
    devops_user = "arn:aws:iam::${var.account_id}:user/devops"                   # Terraform에서 EKS에 대한 전체 제어
  }

  # EKS 클러스터에 Viewer 권한으로 접근
  rbac_developer_users = {
    developer_role = "arn:aws:iam::${var.account_id}:role/cross-account-developer-role"
  }
}

# ECR 접근을 위한 IAM 정책 연결
resource "aws_iam_role_policy_attachment" "node_ecr_readonly" {
  for_each = {
    for ng_key, ng_mod in module.eks.eks_managed_node_groups :
    ng_key => ng_mod.iam_role_name
  }

  role       = replace(each.value, "arn:aws:iam::[0-9]+:role/", "")
  policy_arn = "arn:aws:iam::aws:policy/AmazonEC2ContainerRegistryReadOnly"
}

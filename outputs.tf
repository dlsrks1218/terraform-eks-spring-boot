// EKS 클러스터 API 서버 엔드포인트
output "cluster_endpoint" {
  description = "EKS cluster endpoint"
  value       = module.eks.cluster_endpoint
}

// EKS 클러스터 보안 그룹 ID
output "eks_cluster_security_group_id" {
  description = "EKS 클러스터 보안 그룹 ID"
  value       = module.eks.cluster_security_group_id
}

// VPC ID
output "vpc_id" {
  description = "클러스터가 생성된 VPC ID"
  value       = module.vpc.default_vpc_id
}

// 워크로드를 배포할 프라이빗 서브넷 ID
output "private_subnet_ids" {
  description = "프라이빗 서브넷 ID 목록"
  value       = module.vpc.private_subnets
}

// ALB 배포될 퍼블릭 서브넷 ID
output "public_subnet_ids" {
  description = "퍼블릭 서브넷 ID 목록"
  value       = module.vpc.public_subnets
}

// ALB DNS
output "alb_dns_name" {
  description = "ALB DNS name for the hello-alb ingress"
  value       = kubernetes_ingress_v1.alb.status[0].load_balancer[0].ingress[0].hostname
}

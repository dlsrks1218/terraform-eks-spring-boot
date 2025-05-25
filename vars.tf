variable "aws_region" {
  description = "default region"
  default     = "ap-northeast-2"
}

variable "account_id" {
  description = "aws account id"
  type        = string
  default     = "xxxxxxxxxxxx"
}

## 필수 공용 Tag
variable "resource_name" {
  description = "AWS Resource name" # AWS 리소스 명(EC2, RDS, S3, Cloudfront..)
  type        = string
  default     = "EKS"
}

variable "solution_name" {
  description = "Solution name" # 솔루션, 프로젝트 명
  type        = string
  default     = "test"
}

variable "alias" {
  description = "Alias name" # (API Backend의 backend, 스케줄러의 경우 scheduler..)
  type        = string
  default     = ""
}

variable "environment" {
  description = "Deploy environment" # 서버 환경, production-development는 개발/상용 환경이 함께 있는 경우
  type        = string
  default     = "test"
}

variable "terraform" {
  description = "Managed by Terraform" # Terraform 적용 여부
  type        = bool
  default     = true
}

# Terraform 0.12 and later syntax
variable "additional_tags" {
  description = "Additional resource tags"
  type        = map(string)
  default     = {}
}

variable "cluster_name" {
  description = "EKS 클러스터 이름"
  type        = string
  default     = "test-cluster"
}

variable "cluster_version" {
  description = "Kubernetes 버전"
  type        = string
  default     = "1.32"
}

variable "endpoint_public_access" {
  description = "퍼블릭 API 서버 엔드포인트 활성화 여부"
  type        = bool
  default     = true
}

variable "endpoint_private_access" {
  description = "프라이빗 API 서버 엔드포인트 활성화 여부"
  type        = bool
  default     = true
}

variable "image_uri" {
  description = "배포할 컨테이너 이미지 URI"
  type        = string
  default     = "<ACCOUNT_ID>.dkr.ecr.ap-northeast-2.amazonaws.com/<REPO_NAME>"
}

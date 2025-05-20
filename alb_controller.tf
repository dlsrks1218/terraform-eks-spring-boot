
locals {
  lb_controller_iam_role_name        = "alb-controller-iam-role"
  lb_controller_service_account_name = "aws-load-balancer-controller"

  lb_values = templatefile("${path.module}/values.yaml.tpl", {
    cluster_id             = var.cluster_name
    service_account_create = true
    service_account_name   = local.lb_controller_service_account_name
    role_arn               = module.lb_controller_role.iam_role_arn
    region                 = var.aws_region
    vpc_id                 = module.vpc.vpc_id
    image_repo             = "public.ecr.aws/eks/aws-load-balancer-controller"
    image_tag              = "v2.13.2"
  })
}

data "aws_eks_cluster_auth" "this" {
  name       = module.eks.cluster_name
  depends_on = [module.eks]
}

provider "helm" {
  kubernetes {
    host                   = module.eks.cluster_endpoint
    token                  = data.aws_eks_cluster_auth.this.token
    cluster_ca_certificate = base64decode(module.eks.cluster_certificate_authority_data)
  }
}

module "lb_controller_role" {
  source = "terraform-aws-modules/iam/aws//modules/iam-assumable-role-with-oidc"

  create_role = true

  role_name        = local.lb_controller_iam_role_name
  role_path        = "/"
  role_description = "Role for AWS Load Balancer Controller"

  role_permissions_boundary_arn = ""

  provider_url = replace(module.eks.cluster_oidc_issuer_url, "https://", "")
  oidc_fully_qualified_subjects = [
    "system:serviceaccount:kube-system:${local.lb_controller_service_account_name}"
  ]
  oidc_fully_qualified_audiences = [
    "sts.amazonaws.com"
  ]
  depends_on = [module.eks, data.aws_eks_cluster_auth.this]
}

data "local_file" "iam_policy" {
  filename = "./alb_controller_iam_policy.json"
}

resource "aws_iam_role_policy" "controller" {
  name_prefix = "AWSLoadBalancerControllerIAMPolicy"
  policy      = data.local_file.iam_policy.content
  role        = module.lb_controller_role.iam_role_name
  depends_on  = [module.eks, data.aws_eks_cluster_auth.this]
}

resource "helm_release" "release" {
  name       = "aws-load-balancer-controller"
  chart      = "aws-load-balancer-controller"
  repository = "https://aws.github.io/eks-charts"
  namespace  = "kube-system"
  values     = [local.lb_values]
  depends_on = [module.eks, data.aws_eks_cluster_auth.this]
}

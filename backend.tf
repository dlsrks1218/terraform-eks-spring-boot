terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.46"
    }
  }
  backend "remote" {
    hostname     = "app.terraform.io"
    organization = "aws-test"

    workspaces {
      name = "test-cluster"
    }
  }
}

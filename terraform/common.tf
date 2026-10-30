terraform {
  required_version = ">= 1.10"

  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 6.0"
    }
  }

  # State lives in S3. bucket + region differ per account, so they're passed in:
  # terraform init -backend-config="bucket=lf-learn-<env>-tf-state-<account_id>" -backend-config="region=<region>"
  backend "s3" {
    key          = "terraform.tfstate"
    use_lockfile = true
  }
}

# Use local.account_id in any .tf file in this folder
data "aws_caller_identity" "current" {}

locals {
  account_id = data.aws_caller_identity.current.account_id
}

provider "aws" {
  region = var.aws_region

  default_tags {
    tags = {
      project     = var.project_name
      environment = var.environment
      managed_by  = "terraform"
    }
  }
}

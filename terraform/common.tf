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

terraform {
  required_version = ">= 1.10"

  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 6.0"
    }
  }

  # State lives in S3. Defaults point at dev so `terraform init` works locally.
  # The workflow overrides bucket with -backend-config for the chosen env.
  backend "s3" {
    bucket       = "lf-learn-dev-tf-state-903036621622"
    key          = "terraform.tfstate"
    region       = "ap-southeast-1"
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

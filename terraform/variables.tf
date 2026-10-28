variable "aws_region" {
  type        = string
  description = "Region for all resources"
}

variable "project_name" {
  type        = string
  description = "Prefix used in resource names"
}

variable "environment" {
  type        = string
  description = "dev / prod"
}

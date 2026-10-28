# Looks up the account ID of whoever is running Terraform
data "aws_caller_identity" "current" {}

locals {
  account_id = data.aws_caller_identity.current.account_id

  # Every bucket name: <project>-<env>-<purpose>-<account_id>
  # e.g. "${local.bucket_prefix}-processed-${local.account_id}"
  #   -> lf-learn-dev-processed-903036621622
  bucket_prefix = "${var.project_name}-${var.environment}"
}

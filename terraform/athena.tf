# athena.tf: one workgroup per role, e.g. lf-learn-dev-<id>-customer-service
resource "aws_athena_workgroup" "role" {
  for_each      = local.lf_roles
  name          = "${local.name_prefix}-${each.key}"
  force_destroy = true
  configuration {
    enforce_workgroup_configuration = true
    result_configuration {
      output_location = "s3://${aws_s3_bucket.iceberg.bucket}/athena-results/${each.key}/"
    }
  }
}

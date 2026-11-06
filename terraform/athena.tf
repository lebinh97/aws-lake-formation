# One Athena workgroup per env: lf-learn-<env>-<account_id>
resource "aws_athena_workgroup" "main" {
  name          = local.name_prefix
  force_destroy = true # lets destroy delete it even when it has query history

  configuration {
    enforce_workgroup_configuration = true # every query in this workgroup writes results here
    result_configuration {
      output_location = "s3://${aws_s3_bucket.iceberg.bucket}/athena-results/"
    }
  }
}

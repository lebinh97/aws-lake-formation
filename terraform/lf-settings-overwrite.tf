# Account-wide LF settings (replaces all of them)
resource "aws_lakeformation_data_lake_settings" "main" {
  admins = [
    "arn:aws:iam::${local.account_id}:role/github-terraform", # GHA role must stay admin
    "arn:aws:iam::${local.account_id}:user/test1",            # console user: see all tags + permissions
  ]

  # No default permission blocks = new tables don't get IAM_ALLOWED_PRINCIPALS: ALL
}

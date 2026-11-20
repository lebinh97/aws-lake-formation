# Account-wide LF settings (replaces all of them)
resource "aws_lakeformation_data_lake_settings" "main" {
  admins = [
    "arn:aws:iam::${local.account_id}:role/github-terraform", # GHA role must stay admin
    "arn:aws:iam::${local.account_id}:user/test1",            # console user: see all tags + permissions
  ]

  # No default permission blocks = new tables don't get IAM_ALLOWED_PRINCIPALS: ALL
}

# Register the bucket in LF: queries then get S3 access from LF (only for the data they're granted),
# so the roles need no s3:GetObject of their own
resource "aws_lakeformation_resource" "iceberg" {
  arn      = aws_s3_bucket.iceberg.arn
  role_arn = aws_iam_role.lf_data_access.arn # our own role: the service-linked one blocks destroy

  depends_on = [
    aws_lakeformation_data_lake_settings.main, # created after the LF settings, destroyed before them
    aws_iam_role_policy.lf_data_access,        # role can reach S3 before the bucket is registered
  ]
}

# Role LF uses to read/write the bucket for queries: lf-learn-<env>-<account_id>-lf-data-access
resource "aws_iam_role" "lf_data_access" {
  name = "${local.name_prefix}-lf-data-access"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Effect    = "Allow"
      Action    = "sts:AssumeRole"
      Principal = { Service = "lakeformation.amazonaws.com" }
    }]
  })
}

resource "aws_iam_role_policy" "lf_data_access" {
  name = "iceberg-bucket"
  role = aws_iam_role.lf_data_access.id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      { # bucket actions
        Effect   = "Allow"
        Action   = ["s3:ListBucket", "s3:GetBucketLocation"]
        Resource = aws_s3_bucket.iceberg.arn
      },
      { # file actions: Iceberg reads, writes and deletes data + metadata files
        Effect   = "Allow"
        Action   = ["s3:GetObject", "s3:PutObject", "s3:DeleteObject"]
        Resource = "${aws_s3_bucket.iceberg.arn}/*"
      },
    ]
  })
}

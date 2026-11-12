# Holds Iceberg table data (Parquet) + metadata: lf-learn-<env>-<account_id>-iceberg-storage
resource "aws_s3_bucket" "iceberg" {
  bucket        = "${local.name_prefix}-iceberg-storage"
  force_destroy = true # lets destroy delete it even when it has files
}

# Register the bucket in LF: queries then get S3 access from LF (only for the data they're granted),
# so the roles need no s3:GetObject of their own
resource "aws_lakeformation_resource" "iceberg" {
  arn                     = aws_s3_bucket.iceberg.arn
  use_service_linked_role = true # LF reads S3 with its own AWS-managed role

  depends_on = [aws_lakeformation_data_lake_settings.main] # created after the LF settings, destroyed before them
}

resource "aws_s3_bucket_public_access_block" "iceberg" {
  bucket                  = aws_s3_bucket.iceberg.id
  block_public_acls       = true
  block_public_policy     = true
  ignore_public_acls      = true
  restrict_public_buckets = true
}

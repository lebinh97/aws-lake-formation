# Holds Iceberg table data (Parquet) + metadata: lf-learn-<env>-<account_id>-iceberg-storage
resource "aws_s3_bucket" "iceberg" {
  bucket        = "${local.name_prefix}-iceberg-storage"
  force_destroy = true # lets destroy delete it even when it has files
}

resource "aws_s3_bucket_public_access_block" "iceberg" {
  bucket                  = aws_s3_bucket.iceberg.id
  block_public_acls       = true
  block_public_policy     = true
  ignore_public_acls      = true
  restrict_public_buckets = true
}

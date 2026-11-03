# Holds Iceberg table data (Parquet) + metadata: lf-learn-iceberg-storage-<env>-<account_id>
resource "aws_s3_bucket" "iceberg" {
  bucket        = "${var.project_name}-iceberg-storage-${var.environment}-${local.account_id}"
  force_destroy = true # lets destroy delete it even when it has files
}

resource "aws_s3_bucket_public_access_block" "iceberg" {
  bucket                  = aws_s3_bucket.iceberg.id
  block_public_acls       = true
  block_public_policy     = true
  ignore_public_acls      = true
  restrict_public_buckets = true
}

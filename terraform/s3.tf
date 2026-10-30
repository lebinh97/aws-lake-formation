# Holds table data (Parquet) and Iceberg metadata: lf-learn-<env>-processed-<account_id>
resource "aws_s3_bucket" "processed" {
  bucket        = "${var.project_name}-${var.environment}-processed-${local.account_id}"
  force_destroy = true # lets destroy delete it even when it has files
}

resource "aws_s3_bucket_public_access_block" "processed" {
  bucket                  = aws_s3_bucket.processed.id
  block_public_acls       = true
  block_public_policy     = true
  ignore_public_acls      = true
  restrict_public_buckets = true
}

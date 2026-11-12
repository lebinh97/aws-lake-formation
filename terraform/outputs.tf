# Read by the workflow and passed to scripts/athena_ddl.py
output "glue_database_name" {
  value = aws_glue_catalog_database.main.name
}

output "iceberg_bucket" {
  value = aws_s3_bucket.iceberg.bucket
}

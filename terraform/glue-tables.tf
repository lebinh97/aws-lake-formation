locals {
  # Created once by hand (like the state bucket): lf-learn-<env>-processed-<account_id>
  processed_bucket = "${var.project_name}-${var.environment}-processed-${local.account_id}"

  # Every data-contracts/*-data-contract.json becomes one table, keyed by clean table name
  contracts = {
    for f in fileset("${path.module}/../data-contracts", "*-data-contract.json") :
    replace(lower(jsondecode(file("${path.module}/../data-contracts/${f}")).tablename), "-", "_")
    => jsondecode(file("${path.module}/../data-contracts/${f}"))
  }
}

# Iceberg v2 table per contract. Glue writes the first metadata.json
# into s3://<processed bucket>/<table>/metadata/
resource "aws_glue_catalog_table" "tables" {
  for_each = local.contracts

  name          = each.key
  database_name = aws_glue_catalog_database.main.name
  description   = try(each.value.description, null)
  table_type    = "EXTERNAL_TABLE"

  open_table_format_input {
    iceberg_input {
      metadata_operation = "CREATE"
      version            = "2"
    }
  }

  storage_descriptor {
    location = "s3://${local.processed_bucket}/${each.key}/"

    dynamic "columns" {
      for_each = each.value.columns
      content {
        name    = lower(columns.value.name)
        type    = columns.value.type
        comment = try(columns.value.description, null)
      }
    }
  }

  # Glue/Iceberg set parameters (table_type, metadata_location) themselves.
  # Without this, the next plan would try to remove them and break the table.
  lifecycle {
    ignore_changes = [parameters]
  }
}

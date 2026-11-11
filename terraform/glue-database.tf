# Glue/Athena names can't contain "-", so "lf-learn" + "dev" -> "lf_learn_dev"
resource "aws_glue_catalog_database" "main" {
  name        = replace(local.name_prefix, "-", "_") # lf_learn_dev_903036621622 (Glue/Athena names can't have "-")
  description = "Lake Formation learning database (${var.environment})"

  depends_on = [aws_lakeformation_data_lake_settings.main] # created after the LF settings, destroyed before them
}

# Glue/Athena names can't contain "-", so "lf-learn" + "dev" -> "lf_learn_dev"
resource "aws_glue_catalog_database" "main" {
  name        = replace("${var.project_name}_${var.environment}", "-", "_")
  description = "Lake Formation learning database (${var.environment})"
}

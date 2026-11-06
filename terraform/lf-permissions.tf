# LF layer: which data each role in lf-resources/lf-roles.yml can see

# See the database (it has no tags, so it's granted by name)
resource "aws_lakeformation_permissions" "database" {
  for_each    = local.lf_roles
  principal   = aws_iam_role.lf[each.key].arn
  permissions = ["DESCRIBE"]

  database {
    name = aws_glue_catalog_database.main.name
  }
}

# Tables + columns whose LF-tags match the role's "tags", e.g. privacy IN (non-PII) AND confidentiality IN (internal)
resource "aws_lakeformation_permissions" "tables" {
  for_each    = local.lf_roles
  principal   = aws_iam_role.lf[each.key].arn
  permissions = each.value.permissions

  lf_tag_policy {
    resource_type = "TABLE"

    dynamic "expression" {
      for_each = each.value.tags
      content {
        key    = expression.key
        values = expression.value
      }
    }
  }

  depends_on = [aws_lakeformation_lf_tag.this] # tags must exist before they can be granted
}

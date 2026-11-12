# Roles come from lf-resources/lf-roles.yml (edit there, not here): lf-learn-<env>-<account_id>-<name>

resource "aws_iam_role" "lf" {
  for_each    = local.lf_roles
  name        = "${local.name_prefix}-${each.key}"
  description = each.value.description

  # Who can become this role: the "assumed_by" service and/or the "test_users" from the YAML
  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Effect = "Allow"
      Action = "sts:AssumeRole"
      Principal = merge(
        try({ Service = each.value.assumed_by }, {}),
        try({ AWS = [for u in each.value.test_users : "arn:aws:iam::${local.account_id}:user/${u}"] }, {}),
      )
    }]
  })
}

# IAM layer: lets the role call Athena / Glue / LF at all. Which data it sees is decided by LF (lf-permissions.tf)
resource "aws_iam_role_policy" "lf" {
  for_each = local.lf_roles
  name     = "query-with-athena"
  role     = aws_iam_role.lf[each.key].id

  policy = jsonencode({
    Version = "2012-10-17"
    # Statements 1-4: Athena (workgroups + query results). Statements 5-6: Glue Data Catalog + Lake Formation
    Statement = [
      { # console: list workgroups so this env's one can be picked in the dropdown
        Effect   = "Allow"
        Action   = "athena:ListWorkGroups"
        Resource = "*"
      },
      { # run queries only in this role's own workgroup
        Effect   = "Allow"
        Action   = ["athena:StartQueryExecution", "athena:GetQueryExecution", "athena:GetQueryResults", "athena:StopQueryExecution", "athena:GetWorkGroup"]
        Resource = aws_athena_workgroup.role[each.key].arn
      },
      { # bucket actions (the bucket itself, not its files)
        Effect   = "Allow"
        Action   = ["s3:GetBucketLocation", "s3:ListBucket"]
        Resource = aws_s3_bucket.iceberg.arn
      },
      { # file actions: only this role's query results
        Effect   = "Allow"
        Action   = ["s3:GetObject", "s3:PutObject"]
        Resource = "${aws_s3_bucket.iceberg.arn}/athena-results/${each.key}/*"
      },
      { # read table definitions
        Effect = "Allow"
        Action = ["glue:GetDatabase", "glue:GetDatabases", "glue:GetTable", "glue:GetTables"]
        Resource = [
          "arn:aws:glue:${var.aws_region}:${local.account_id}:catalog",
          "arn:aws:glue:${var.aws_region}:${local.account_id}:database/${aws_glue_catalog_database.main.name}",
          "arn:aws:glue:${var.aws_region}:${local.account_id}:table/${aws_glue_catalog_database.main.name}/*",
        ]
      },
      { # ask LF for temporary credentials to read the table files
        Effect   = "Allow"
        Action   = "lakeformation:GetDataAccess"
        Resource = "*"
      }
    ]
  })
}

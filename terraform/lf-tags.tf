# LF-tag keys + allowed values come from lf-tags/lf-tags.json (edit there, not here)
locals {
  lf_tags = jsondecode(file("${path.module}/../lf-tags/lf-tags.json"))
}

resource "aws_lakeformation_lf_tag" "this" {
  for_each = local.lf_tags
  key      = each.key
  values   = each.value.values # "description" is only for people reading the JSON, AWS has no field for it
}

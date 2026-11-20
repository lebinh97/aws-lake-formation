# TEST - Lambda in a VPC: race condition between the Lambda and its policy attachment. Delete after the test.
# The Lambda only references the ROLE, not the policy ATTACHMENT, so Terraform creates both at the same time.
# If the Lambda is first -> "execution role does not have permission to call CreateNetworkInterface on EC2"
# Fix: uncomment depends_on in the Lambda.

data "aws_vpc" "default" {
  default = true
}

data "aws_subnets" "default" {
  filter {
    name   = "vpc-id"
    values = [data.aws_vpc.default.id]
  }
}

resource "aws_iam_role" "test_lambda" {
  name = "${local.name_prefix}-test-lambda"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Effect    = "Allow"
      Action    = "sts:AssumeRole"
      Principal = { Service = "lambda.amazonaws.com" }
    }]
  })
}

# Minimal ENI permissions Lambda needs to run inside a VPC (no CloudWatch Logs).
# ec2 Describe* / CreateNetworkInterface don't support resource-level scoping well -> "*"
resource "aws_iam_role_policy" "test_vpc" {
  name = "vpc-eni"
  role = aws_iam_role.test_lambda.id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Effect = "Allow"
      Action = [
        "ec2:CreateNetworkInterface",
        "ec2:DescribeNetworkInterfaces",
        "ec2:DeleteNetworkInterface",
      ]
      Resource = "*"
    }]
  })
}

resource "aws_security_group" "test_lambda" {
  name   = "${local.name_prefix}-test-lambda"
  vpc_id = data.aws_vpc.default.id
}

# Tiny Python handler, zipped on the GHA runner
data "archive_file" "test" {
  type        = "zip"
  output_path = "${path.module}/test-lambda.zip"

  source {
    content  = "def handler(event, context):\n    return 'ok'\n"
    filename = "index.py"
  }
}

resource "aws_lambda_function" "test" {
  function_name    = "${local.name_prefix}-test"
  role             = aws_iam_role.test_lambda.arn # only the role, NOT the attachment -> race
  runtime          = "python3.12"
  handler          = "index.handler"
  filename         = data.archive_file.test.output_path
  source_code_hash = data.archive_file.test.output_base64sha256

  vpc_config {
    subnet_ids         = data.aws_subnets.default.ids
    security_group_ids = [aws_security_group.test_lambda.id]
  }

  # FIX: attach the policy first (and on destroy, delete the Lambda before removing the policy)
  # depends_on = [aws_iam_role_policy.test_vpc]
}

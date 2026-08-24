resource "aws_kms_key" "lambda_env" {
  description         = "KMS key for ${var.environment} Lambda environment variables"
  enable_key_rotation = true

  tags = {
    Environment = var.environment
    ManagedBy   = "terraform"
  }
}

resource "aws_kms_alias" "lambda_env" {
  name          = "alias/${var.environment}-lambda-env"
  target_key_id = aws_kms_key.lambda_env.key_id
}

data "archive_file" "lambda" {
  type        = "zip"
  source_file = "${path.module}/app.py"
  output_path = "${path.root}/lambda.zip"
}

resource "aws_cloudwatch_log_group" "lambda" {
  name              = "/aws/lambda/${var.lambda_name}"
  retention_in_days = 365
  kms_key_id        = var.kms_key_arn

  tags = {
    Environment = var.environment
    ManagedBy   = "terraform"
  }
}

resource "aws_lambda_function" "health" {

  #checkov:skip=CKV_AWS_116:Lambda is invoked synchronously through API Gateway and does not use asynchronous events
  #checkov:skip=CKV_AWS_272:Code signing is not required for this internal health-check Lambda

  function_name = var.lambda_name
  filename = data.archive_file.lambda.output_path

  kms_key_arn = aws_kms_key.lambda_env.arn

  handler = "app.lambda_handler"
  runtime = "python3.12"

  role = var.lambda_role


  source_code_hash = filebase64sha256("${data.archive_file.lambda.output_path}")

  environment {
    variables = {
      TABLE_NAME = var.table_name
    }
  }
  depends_on = [
    aws_cloudwatch_log_group.lambda
  ]

}


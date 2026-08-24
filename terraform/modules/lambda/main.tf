data "archive_file" "lambda" {
  type        = "zip"
  source_file = "${path.module}/app.py"
  output_path = "${path.root}/lambda.zip"
}


resource "aws_cloudwatch_log_group" "lambda" {
  name              = "/aws/lambda/${var.lambda_name}"
  retention_in_days = 14
  tags = {
    Environment = var.environment
    ManagedBy   = "terraform"
  }
}

resource "aws_lambda_function" "health" {
  function_name = var.lambda_name
  filename = data.archive_file.lambda.output_path


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


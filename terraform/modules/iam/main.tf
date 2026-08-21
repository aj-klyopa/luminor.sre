data "aws_caller_identity" "current" {}

data "aws_iam_policy_document" "assume_lambda" {
  statement {
    sid = "AllowLambdaAssumeRole"

    actions = ["sts:AssumeRole"]

    principals {
      type        = "Service"
      identifiers = ["lambda.amazonaws.com"]
    }
  }
}

resource "aws_iam_role" "lambda_role" {
  name               = "${var.environment}-lambda-role"
  assume_role_policy = data.aws_iam_policy_document.assume_lambda.json
}

data "aws_iam_policy_document" "lambda_policy" {
  statement {
    sid = "WriteLambdaLogs"
    actions = [
      "logs:CreateLogStream",
      "logs:PutLogEvents"
    ]
    resources = [
      "arn:aws:logs:${var.aws_region}:${data.aws_caller_identity.current.account_id}:log-group:/aws/lambda/${var.lambda_name}:log-stream:*"
    ]
  }
  statement {
    sid = "WriteToDynamoDB"
    actions = [
      "dynamodb:PutItem"
    ]
    resources = [
      var.dynamodb_arn
    ]
  }
}

resource "aws_iam_policy" "lambda_policy" {
  name   = "${var.environment}-lambda-policy"
  policy = data.aws_iam_policy_document.lambda_policy.json
}

resource "aws_iam_role_policy_attachment" "attach_lambda_policy" {
  role       = aws_iam_role.lambda_role.name
  policy_arn = aws_iam_policy.lambda_policy.arn
}
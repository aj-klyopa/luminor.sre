data "aws_region" "current" {}
data "aws_caller_identity" "current" {}

#checkov:skip=CKV_AWS_109:KMS key policy grants full key administration only to the account root principal
#checkov:skip=CKV_AWS_111:KMS key policy grants full key administration only to the account root principal
#checkov:skip=CKV_AWS_356:KMS key policy uses resource "*" as required by KMS key policies; access is constrained by principal and encryption context
data "aws_iam_policy_document" "logs_kms" {


  #checkov:skip=CKV_AWS_109:KMS key policy grants full key administration only to the account root principal
  #checkov:skip=CKV_AWS_111:KMS key policy grants full key administration only to the account root principal
  #checkov:skip=CKV_AWS_356:KMS key policy uses resource "*" as required by KMS key policies; access is constrained by principal and encryption context
  statement {
    sid    = "EnableRootAccountPermissions"
    effect = "Allow"

    principals {
      type = "AWS"
      identifiers = [
        "arn:aws:iam::${data.aws_caller_identity.current.account_id}:root"
      ]
    }

    actions   = ["kms:*"]
    resources = ["*"]
  }

  statement {
    sid    = "AllowCloudWatchLogs"
    effect = "Allow"

    principals {
      type        = "Service"
      identifiers = ["logs.${data.aws_region.current.name}.amazonaws.com"]
    }

    actions = [
      "kms:Encrypt",
      "kms:Decrypt",
      "kms:ReEncrypt*",
      "kms:GenerateDataKey*",
      "kms:DescribeKey"
    ]

    resources = ["*"]

    condition {
      test     = "ArnLike"
      variable = "kms:EncryptionContext:aws:logs:arn"

      values = [
        "arn:aws:logs:${data.aws_region.current.name}:${data.aws_caller_identity.current.account_id}:log-group:*"
      ]
    }
  }
}

resource "aws_kms_key" "logs" {
  description         = "KMS key for ${var.environment} CloudWatch logs"
  enable_key_rotation = true

  tags = {
    Environment = var.environment
    ManagedBy   = "terraform"
  }
}

resource "aws_kms_alias" "logs" {
  name          = "alias/${var.environment}-cloudwatch-logs"
  target_key_id = aws_kms_key.logs.key_id
}

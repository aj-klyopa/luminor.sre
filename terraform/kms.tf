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

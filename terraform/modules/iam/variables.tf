variable "environment" {}
variable "dynamodb_arn" {}
variable "aws_region" {}
variable "lambda_name" {}
variable "dynamodb_kms_key_arn" {
  description = "ARN of the KMS key used to encrypt DynamoDB"
  type        = string
}


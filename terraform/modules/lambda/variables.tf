variable "environment" {}
variable "lambda_role" {}
variable "lambda_name" {}
variable "table_name" {}
variable "kms_key_arn" {}

variable "dynamodb_kms_key_arn" {
  description = "ARN of the KMS key used to encrypt DynamoDB"
  type        = string
}

output "table_name" {
  value = aws_dynamodb_table.requests.name
}

output "table_arn" {
  value = aws_dynamodb_table.requests.arn
}

output "kms_key_arn" {
  value = aws_kms_key.dynamodb.arn
}


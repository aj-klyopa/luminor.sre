output "lambda_arn" {
  value = aws_lambda_function.health.arn
}

output "lambda_name" {
  value = aws_lambda_function.health.function_name
}
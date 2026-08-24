locals {
  prefix      = var.environment
  lambda_name = "${var.environment}-health-check"
}

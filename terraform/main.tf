module "dynamodb" {
  source      = "./modules/dynamodb"
  environment = var.environment
}

module "iam" {
  source       = "./modules/iam"
  environment  = var.environment
  aws_region   = var.aws_region
  lambda_name  = local.lambda_name
  dynamodb_arn = module.dynamodb.table_arn
}

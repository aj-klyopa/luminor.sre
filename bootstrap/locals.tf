locals {
  tfstate_bucket_name = "${var.environment}-${var.project_name}-tfstate"
  github_role_name    = "${var.environment}-${var.project_name}-github-actions-role"
}

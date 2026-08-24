# Serverless Health Check API with CI/CD

## Overview

This project implements a serverless health check API on AWS using:

- AWS Lambda
- Amazon API Gateway
- Amazon DynamoDB
- Terraform
- GitHub Actions

The solution supports two isolated environments:

- `staging`
- `prod`

All AWS infrastructure is provisioned using Terraform and follows the required naming convention:

```text
<environment>-<resource-name>
```

Examples:

```text
staging-health-check-function
prod-requests-db
```

---

# Architecture

The solution contains:

- API Gateway HTTP endpoint (`/health`)
- AWS Lambda function
- DynamoDB table for request storage
- CloudWatch logging
- IAM roles with scoped permissions
- Terraform remote state stored in S3
- GitHub Actions deployment pipeline using AWS OIDC authentication

---

# Repository Structure

```text
.
├── bootstrap/
├── terraform/
│   ├── backend/
│   ├── lambda/
│   └── modules/
│       ├── apigw/
│       ├── dynamodb/
│       ├── iam/
│       └── lambda/
├── environments/
├── .github/workflows/
└── README.md
```

---

# Supported Environments

Two isolated environments are supported:

- `staging`
- `prod`

Environment-specific configuration is defined using Terraform variable files.

---

# Terraform Requirements

The project has been tested with the following versions:

| Tool | Version |
|------|----------|
| Terraform | `>= 1.6` |
| AWS Provider | `~> 5.0` |

Make sure you are using compatible versions before running the project.

---

# Prerequisites

Before using GitHub Actions deployment, create an AWS IAM Identity Provider for GitHub OIDC authentication.

Also, add the AWS account ID as a GitHub Actions variable:

**GitHub repository → Settings → Secrets and variables → Actions → Variables → New repository variable**

- **Name:** `AWS_ACCOUNT_ID`
- **Value:** `<AWS Account ID>`

## AWS OIDC Provider

Create an AWS IAM Identity Provider with the following configuration.

### Provider type

```text
OpenID Connect
```

### Provider URL

```text
https://token.actions.githubusercontent.com
```

### Audience

```text
sts.amazonaws.com
```

---

# Environment Configuration

Environment-specific variables must be configured in the following locations.

## Terraform variables

Directory:

```text
environments/
```

Files:

```text
staging.tfvars
prod.tfvars
common.tfvars
```

## Terraform backend configuration

Directory:

```text
terraform/backend/
```

Files:

```text
staging.hcl
prod.hcl
```

---

# Bootstrap Infrastructure

The bootstrap configuration creates:

- Terraform remote state S3 bucket
- GitHub Actions IAM deployment role
- Required IAM/OIDC integration

Bootstrap must be executed manually before using the main Terraform configuration.

Terraform workspaces are used to isolate bootstrap state between environments.

---

# Bootstrap Commands

Run the following commands for each environment separately.

## Staging

```bash
cd bootstrap

terraform workspace new staging
terraform workspace select staging

terraform plan \
  -var-file="../environments/staging.tfvars" \
  -var-file="../environments/common.tfvars"

terraform apply \
  -var-file="../environments/staging.tfvars" \
  -var-file="../environments/common.tfvars"
```

## Production

```bash
cd bootstrap

terraform workspace new prod
terraform workspace select prod

terraform plan \
  -var-file="../environments/prod.tfvars" \
  -var-file="../environments/common.tfvars"

terraform apply \
  -var-file="../environments/prod.tfvars" \
  -var-file="../environments/common.tfvars"
```

---

# GitHub Actions Deployment Role

GitHub Actions uses AWS OIDC authentication to assume a deployment IAM role.

> The GitHub Actions deployment role currently uses `AdministratorAccess`
> for simplicity during infrastructure bootstrap and development.
>
> In a production-grade setup, this should be replaced with least-privilege
> IAM policies scoped only to the Terraform-managed resources.

---

# Infrastructure Deployment

Infrastructure deployment can be performed in two ways.

---

Before running Terraform manually, AWS credentials must be available in the credentials file referenced by the `AWS_SHARED_CREDENTIALS_FILE` environment variable.

Example:

```bash
export AWS_SHARED_CREDENTIALS_FILE=/path/to/credentials
```

Windows PowerShell:

```powershell
$env:AWS_SHARED_CREDENTIALS_FILE="C:\path\to\credentials"
```


# 1. Manual Deployment

Terraform can be executed manually.

## Staging

```bash
cd terraform

terraform init \
  -backend-config="backend/staging.hcl" \
  -reconfigure

terraform plan \
  -var-file="../environments/staging.tfvars" \
  -var-file="../environments/common.tfvars"

terraform apply \
  -var-file="../environments/staging.tfvars" \
  -var-file="../environments/common.tfvars"
```

## Production

```bash
cd terraform

terraform init \
  -backend-config="backend/prod.hcl" \
  -reconfigure

terraform plan \
  -var-file="../environments/prod.tfvars" \
  -var-file="../environments/common.tfvars"

terraform apply \
  -var-file="../environments/prod.tfvars" \
  -var-file="../environments/common.tfvars"
```

---

# 2. Automatic Deployment with GitHub Actions

Deployments are automated using GitHub Actions.

## Staging deployment

Deployment is automatically triggered after a push to the `staging` branch.

## Production deployment

Deployment is automatically triggered after a merge/pull request into the `main` branch.

---

# CI/CD Pipeline

The GitHub Actions pipeline performs the following steps:

1. Checkout repository
2. Build Lambda deployment package
3. Configure AWS authentication using OIDC
4. Run Terraform format validation
5. Initialize Terraform backend
6. Validate Terraform configuration
7. Execute Terraform plan
8. Apply Terraform changes

The pipeline supports environment-specific deployments for both `staging` and `prod`.

---

# Security Features

Implemented security controls include:

- DynamoDB Server-Side Encryption (SSE)
- Scoped IAM roles
- GitHub OIDC authentication
- Separate Terraform state per environment
- API Gateway throttling
- CloudWatch request logging

---

# Lambda Function Behavior

When the `/health` endpoint is invoked:

1. The incoming request event is logged to CloudWatch
2. A unique request record is stored in DynamoDB
3. The API responds with:

```json
{
  "status": "healthy",
  "message": "Request processed and saved."
}
```

If the request body does not contain the required `payload` field,
the Lambda function returns:

```json
{
  "status": "error",
  "message": "Missing required field: payload"
}
```

with HTTP status code:

```text
400 Bad Request
```

---


The API Gateway hostname is displayed after successful Terraform deployment.

- During manual deployment, the url/output is shown in the terminal after `terraform apply`
- During GitHub Actions deployment, the url/output can be found in the GitHub Actions logs in the `terraform apply` step


# API Testing

Example request:

```bash
curl -X POST \
  https://<api-id>.execute-api.<region>.amazonaws.com/health \
  -H "Content-Type: application/json" \
  -d '{"payload":"test"}'
```

Example successful response:

```json
{
  "status": "healthy",
  "message": "Request processed and saved."
}
```

The API also supports the `GET` method.

Example GET request:

```text
https://<api-id>.execute-api.<region>.amazonaws.com/health?payload=test
```

---

# Design Notes

- Terraform workspaces isolate bootstrap state between environments
- Separate backend configuration is used for each environment
- GitHub Actions uses OIDC instead of long-lived AWS credentials
- Environment-specific configuration is externalized via `.tfvars`
- Infrastructure and Lambda deployment are fully automated through CI/CD
- DynamoDB encryption is enabled using Server-Side Encryption (SSE)

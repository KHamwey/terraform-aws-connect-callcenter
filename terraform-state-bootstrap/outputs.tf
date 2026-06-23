output "state_bucket_name" {
  description = "S3 bucket for Terraform remote state."
  value       = aws_s3_bucket.state.id
}

output "lock_table_name" {
  description = "DynamoDB table for Terraform state locking."
  value       = aws_dynamodb_table.lock.name
}

output "state_key" {
  description = "Recommended state file key for the root module."
  value       = "connect-callcenter/terraform.tfstate"
}

output "github_actions_role_arn" {
  description = "IAM role ARN — set as GitHub secret AWS_ROLE_ARN."
  value       = aws_iam_role.github_actions.arn
}

output "backend_config" {
  description = "Copy into backend.hcl at repo root (or use in terraform init -backend-config=...)."
  value = {
    bucket         = aws_s3_bucket.state.id
    key            = "connect-callcenter/terraform.tfstate"
    region         = var.region
    dynamodb_table = aws_dynamodb_table.lock.name
    encrypt        = true
  }
}

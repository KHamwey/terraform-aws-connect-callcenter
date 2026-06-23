variable "region" {
  description = "AWS region for the state bucket and DynamoDB lock table."
  type        = string
  default     = "us-east-1"
}

variable "prefix" {
  description = "Prefix for state bucket and lock table names (globally unique S3 bucket)."
  type        = string
  default     = "kwade-callcenter-demo"
}

variable "github_org" {
  description = "GitHub org or username that owns the repository."
  type        = string
  default     = "KHamwey"
}

variable "github_repo" {
  description = "GitHub repository name (without org)."
  type        = string
  default     = "terraform-aws-connect-callcenter"
}

variable "github_branches" {
  description = "Branches allowed to assume the GitHub Actions IAM role."
  type        = list(string)
  default     = ["main"]
}

variable "create_github_oidc_provider" {
  description = "Set false if token.actions.githubusercontent.com OIDC provider already exists in the account."
  type        = bool
  default     = true
}

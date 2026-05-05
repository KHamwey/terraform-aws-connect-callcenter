variable "region" {
  description = "AWS region for the Amazon Connect instance and supporting resources."
  type        = string
  default     = "us-east-1"
}

variable "instance_alias" {
  description = "Globally-unique alias for the Amazon Connect instance. Becomes part of the CCP login URL: https://<alias>.my.connect.aws/"
  type        = string
}

# ----------------------------------------------------------------------------
# Step 4 inputs (queue/user) — used once we layer in the agent + queue
# ----------------------------------------------------------------------------

variable "agent_email" {
  description = "Email for the seeded agent user (agent1)."
  type        = string
  default     = ""
}

variable "agent_password" {
  description = "Initial password for agent1. Min 8 chars, must include upper, lower, number. Set in terraform.tfvars (gitignored)."
  type        = string
  default     = ""
  sensitive   = true
}

# ----------------------------------------------------------------------------
# Step 5 inputs (Lex bot) — populated after Step 2 detection
# ----------------------------------------------------------------------------

variable "lex_bot_name" {
  description = "Name of the Lex bot in the AWS account. Used for both V1 association and V2 logging."
  type        = string
  default     = "KylesWebsiteBot"
}

variable "lex_bot_version" {
  description = "Either 'V1' or 'V2'. Detected via the AWS CLI in Step 2. Drives whether we use the bot_associations module input (V1) or a Lex V2 alias resource policy + contact-flow JSON wiring (V2)."
  type        = string
  default     = "V2"

  validation {
    condition     = contains(["V1", "V2"], var.lex_bot_version)
    error_message = "lex_bot_version must be 'V1' or 'V2'."
  }
}

variable "lex_v2_bot_alias_arn" {
  description = "Lex V2 bot alias ARN, e.g. arn:aws:lex:us-east-1:123456789012:bot-alias/ABCD1234/EFGH5678. Required only when lex_bot_version = 'V2'."
  type        = string
  default     = ""
}

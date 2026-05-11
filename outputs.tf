output "instance_id" {
  description = "Amazon Connect instance ID."
  value       = module.amazon_connect.instance_id
}

output "instance_arn" {
  description = "Amazon Connect instance ARN."
  value       = try(module.amazon_connect.instance.arn, null)
}

output "instance_alias" {
  description = "Amazon Connect instance alias (subdomain)."
  value       = var.instance_alias
}

output "ccp_login_url" {
  description = "Contact Control Panel (CCP) login URL for agents."
  value       = "https://${var.instance_alias}.my.connect.aws/ccp-v2/"
}

output "console_url" {
  description = "Direct link to manage this instance in the AWS Console."
  value       = "https://${var.region}.console.aws.amazon.com/connect/v2/app/instance/${module.amazon_connect.instance_id}"
}

# ----------------------------------------------------------------------------
# Web chat widget config — drop these into React-Portfolio's .env
# ----------------------------------------------------------------------------

output "cognito_identity_pool_id" {
  description = "Cognito Identity Pool ID for unauthenticated browser access to the Lex bot. Use as REACT_APP_COGNITO_IDENTITY_POOL_ID."
  value       = aws_cognito_identity_pool.web_chat.id
}

output "lex_bot_id" {
  description = "Lex V2 bot ID. Use as REACT_APP_LEX_BOT_ID."
  value       = local.lex_v2_bot_id
}

output "lex_bot_alias_id" {
  description = "Lex V2 bot alias ID. Use as REACT_APP_LEX_BOT_ALIAS_ID."
  value       = local.lex_v2_bot_alias_id
}

output "lex_locale_id" {
  description = "Lex V2 locale. Use as REACT_APP_LEX_LOCALE_ID."
  value       = "en_US"
}

output "aws_region" {
  description = "AWS region (matches what the widget needs)."
  value       = var.region
}

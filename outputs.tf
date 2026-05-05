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

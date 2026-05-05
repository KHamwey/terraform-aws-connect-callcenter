################################################################################
# Amazon Connect Call Center
#
# Built incrementally across multiple `terraform apply` checkpoints:
#   Step 3 (Apply #1): bare instance only       <-- ACTIVE
#   Step 4 (Apply #2): hours, queue, routing, security profile, user
#   Step 5 (Apply #3): Lex bot wiring (V1 association OR V2 IAM policy)
#   Step 6 (Apply #4): contact flow JSON
#
# Module reference: https://github.com/aws-ia/terraform-aws-amazonconnect
################################################################################

module "amazon_connect" {
  source  = "aws-ia/amazonconnect/aws"
  version = "~> 0.0.1"

  # ---- Step 3: instance ---------------------------------------------------
  instance_identity_management_type  = "CONNECT_MANAGED"
  instance_alias                     = var.instance_alias
  instance_inbound_calls_enabled     = true
  instance_outbound_calls_enabled    = true
  instance_contact_flow_logs_enabled = true

  # ---- Step 4: queue + agent ----------------------------------------------
  hours_of_operations = {
    "BusinessHours" = {
      time_zone   = "America/New_York"
      description = "M-F 7am - 7pm ET"
      config = [
        for d in ["MONDAY", "TUESDAY", "WEDNESDAY", "THURSDAY", "FRIDAY"] : {
          day        = d
          start_time = { hours = 7, minutes = 0 }
          end_time   = { hours = 18, minutes = 59 }
        }
      ]
    }
  }

  # NOTE: Connect auto-creates a default queue named "BasicQueue" when the
  # instance is provisioned, so we use a distinct name here.
  queues = {
    "MainInboundQueue" = {
      description           = "Primary inbound queue routed by InboundMain flow"
      hours_of_operation_id = try(module.amazon_connect.hours_of_operations["BusinessHours"].hours_of_operation_id, null)
    }
  }

  routing_profiles = {
    "InboundVoiceRoutingProfile" = {
      description               = "Voice-only routing for inbound agents"
      default_outbound_queue_id = try(module.amazon_connect.queues["MainInboundQueue"].queue_id, null)
      media_concurrencies       = [{ channel = "VOICE", concurrency = 1 }]
      queue_configs = [{
        channel  = "VOICE"
        delay    = 0
        priority = 1
        queue_id = try(module.amazon_connect.queues["MainInboundQueue"].queue_id, null)
      }]
    }
  }

  security_profiles = {
    "CallCenterAgent" = {
      description = "Inbound voice agent"
      permissions = ["BasicAgentAccess", "OutboundCallAccess"]
    }
  }

  users = {
    "agent1" = {
      password = var.agent_password
      identity_info = {
        email      = var.agent_email
        first_name = "Kyle"
        last_name  = "Hamwey"
      }
      phone_config = {
        phone_type                    = "SOFT_PHONE"
        after_contact_work_time_limit = 0
        auto_accept                   = false
      }
      routing_profile_id   = try(module.amazon_connect.routing_profiles["InboundVoiceRoutingProfile"].routing_profile_id, null)
      security_profile_ids = [try(module.amazon_connect.security_profiles["CallCenterAgent"].security_profile_id, null)]
    }
  }

  # ---- Step 5: Lex bot association (V1 only — uncomment in Step 5) -------
  # bot_associations = var.lex_bot_version == "V1" ? {
  #   (var.lex_bot_name) = {
  #     name       = var.lex_bot_name
  #     lex_region = var.region
  #   }
  # } : {}

  # ---- Step 6: contact flow JSON (uncomment in Step 6) -------------------
  # contact_flows = {
  #   "InboundMain" = {
  #     type         = "CONTACT_FLOW"
  #     description  = "Main inbound entry point"
  #     filename     = "${path.module}/flows/inbound_main.json"
  #     content_hash = filebase64sha256("${path.module}/flows/inbound_main.json")
  #   }
  # }
}

################################################################################
# Lex V2 wiring — only created if var.lex_bot_version == "V2"
# Allows Amazon Connect to invoke the Lex V2 bot alias.
# (V2 bots are referenced by ARN inside the contact flow JSON; there is no
#  Connect-side association resource for V2.)
################################################################################

# resource "aws_lexv2models_bot_alias" "connect_invoke" { ... }
#
# data "aws_iam_policy_document" "lex_v2_invoke" {
#   count = var.lex_bot_version == "V2" ? 1 : 0
#
#   statement {
#     actions   = ["lex:RecognizeText", "lex:RecognizeUtterance", "lex:StartConversation"]
#     resources = [var.lex_v2_bot_alias_arn]
#     principals {
#       type        = "Service"
#       identifiers = ["connect.amazonaws.com"]
#     }
#     condition {
#       test     = "StringEquals"
#       variable = "AWS:SourceAccount"
#       values   = [data.aws_caller_identity.current.account_id]
#     }
#     condition {
#       test     = "ArnEquals"
#       variable = "AWS:SourceArn"
#       values   = [module.amazon_connect.instance.arn]
#     }
#   }
# }

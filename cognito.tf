################################################################################
# Cognito Identity Pool for the React-Portfolio web chat widget
#
# Visitors to the portfolio site are NOT signed in. They get temporary AWS
# credentials from this unauthenticated Cognito Identity Pool, which assume
# the cognito_unauth IAM role. That role has narrowly-scoped permission to
# call Lex V2 RecognizeText / RecognizeUtterance / session APIs against the
# KylesWebsiteBot alias only.
#
# Flow:
#   browser --> cognito.GetId / GetCredentialsForIdentity (no auth)
#           --> temp AWS creds for cognito_unauth role
#           --> lex.RecognizeText against bot alias
################################################################################

locals {
  # Parse bot ID + alias ID from the alias ARN
  # arn:aws:lex:us-east-1:<acct>:bot-alias/<botId>/<aliasId>
  lex_v2_bot_alias_arn_parts = split("/", var.lex_v2_bot_alias_arn)
  lex_v2_bot_id              = local.lex_v2_bot_alias_arn_parts[1]
  lex_v2_bot_alias_id        = local.lex_v2_bot_alias_arn_parts[2]
}

resource "aws_cognito_identity_pool" "web_chat" {
  identity_pool_name               = "${var.instance_alias}-web-chat"
  allow_unauthenticated_identities = true
  allow_classic_flow               = false
}

# Trust policy: only THIS identity pool can assume this role,
# and only for unauthenticated identities.
data "aws_iam_policy_document" "cognito_unauth_assume" {
  statement {
    effect  = "Allow"
    actions = ["sts:AssumeRoleWithWebIdentity"]

    principals {
      type        = "Federated"
      identifiers = ["cognito-identity.amazonaws.com"]
    }

    condition {
      test     = "StringEquals"
      variable = "cognito-identity.amazonaws.com:aud"
      values   = [aws_cognito_identity_pool.web_chat.id]
    }

    condition {
      test     = "ForAnyValue:StringLike"
      variable = "cognito-identity.amazonaws.com:amr"
      values   = ["unauthenticated"]
    }
  }
}

resource "aws_iam_role" "cognito_unauth" {
  name        = "${var.instance_alias}-cognito-unauth"
  description = "Assumed by unauthenticated portfolio site visitors to invoke the Lex bot"

  assume_role_policy = data.aws_iam_policy_document.cognito_unauth_assume.json
}

# Permission policy: only what's strictly needed to chat with the bot alias.
# NOTE: lex:RecognizeUtterance + lex:StartConversation are included so the
# widget can also handle voice/streaming if you enable it later. Drop them
# if you want a strict least-privilege text-only setup.
data "aws_iam_policy_document" "cognito_unauth_lex" {
  statement {
    sid    = "InvokeKylesWebsiteBot"
    effect = "Allow"
    actions = [
      "lex:RecognizeText",
      "lex:RecognizeUtterance",
      "lex:StartConversation",
      "lex:GetSession",
      "lex:PutSession",
      "lex:DeleteSession",
    ]
    resources = [var.lex_v2_bot_alias_arn]
  }
}

resource "aws_iam_role_policy" "cognito_unauth_lex" {
  name   = "InvokeLexBot"
  role   = aws_iam_role.cognito_unauth.id
  policy = data.aws_iam_policy_document.cognito_unauth_lex.json
}

resource "aws_cognito_identity_pool_roles_attachment" "web_chat" {
  identity_pool_id = aws_cognito_identity_pool.web_chat.id

  roles = {
    "unauthenticated" = aws_iam_role.cognito_unauth.arn
  }
}

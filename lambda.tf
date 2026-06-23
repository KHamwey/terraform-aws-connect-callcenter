################################################################################
# After-hours notifier — Connect invokes Lambda with Contact Attributes → SES
################################################################################

locals {
  notification_email = length(trimspace(var.notification_email)) > 0 ? trimspace(var.notification_email) : trimspace(var.agent_email)
  ses_from_email     = length(trimspace(var.ses_from_email)) > 0 ? trimspace(var.ses_from_email) : local.notification_email
}

data "archive_file" "after_hours_notifier" {
  type        = "zip"
  source_file = "${path.module}/lambda/after_hours_notifier.js"
  output_path = "${path.module}/lambda/after_hours_notifier.zip"
}

resource "aws_ses_email_identity" "notification_from" {
  email = local.ses_from_email
}

resource "aws_ses_email_identity" "notification_to" {
  email = local.notification_email
}

data "aws_iam_policy_document" "after_hours_notifier_assume" {
  statement {
    effect  = "Allow"
    actions = ["sts:AssumeRole"]
    principals {
      type        = "Service"
      identifiers = ["lambda.amazonaws.com"]
    }
  }
}

resource "aws_iam_role" "after_hours_notifier" {
  name               = "${var.instance_alias}-after-hours-notifier"
  assume_role_policy = data.aws_iam_policy_document.after_hours_notifier_assume.json
}

resource "aws_iam_role_policy_attachment" "after_hours_notifier_basic" {
  role       = aws_iam_role.after_hours_notifier.name
  policy_arn = "arn:aws:iam::aws:policy/service-role/AWSLambdaBasicExecutionRole"
}

data "aws_iam_policy_document" "after_hours_notifier_ses" {
  statement {
    sid    = "SendNotificationEmail"
    effect = "Allow"
    actions = [
      "ses:SendEmail",
      "ses:SendRawEmail",
    ]
    resources = [
      aws_ses_email_identity.notification_from.arn,
      "arn:aws:ses:${var.region}:${data.aws_caller_identity.current.account_id}:identity/${local.notification_email}",
    ]
  }
}

resource "aws_iam_role_policy" "after_hours_notifier_ses" {
  name   = "ses-send"
  role   = aws_iam_role.after_hours_notifier.id
  policy = data.aws_iam_policy_document.after_hours_notifier_ses.json
}

resource "aws_lambda_function" "after_hours_notification" {
  function_name = "${var.instance_alias}-after-hours-notifier"
  role          = aws_iam_role.after_hours_notifier.arn
  handler       = "after_hours_notifier.handler"
  runtime       = "nodejs20.x"
  timeout       = 10

  filename         = data.archive_file.after_hours_notifier.output_path
  source_code_hash = data.archive_file.after_hours_notifier.output_base64sha256

  environment {
    variables = {
      TO_EMAIL   = local.notification_email
      FROM_EMAIL = local.ses_from_email
    }
  }
}

resource "aws_lambda_permission" "connect_after_hours" {
  statement_id  = "AllowConnectInvoke"
  action        = "lambda:InvokeFunction"
  function_name = aws_lambda_function.after_hours_notification.function_name
  principal     = "connect.amazonaws.com"
  source_arn    = "${module.amazon_connect.instance.arn}/contact-flow/*"
}

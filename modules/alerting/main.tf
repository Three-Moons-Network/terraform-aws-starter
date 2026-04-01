###############################################################################
# Alerting Module — SNS Topics and Subscriptions
#
# Central SNS topic for operational alerts with configurable subscriptions
# (email, SMS). Ensures critical notifications reach the right team.
###############################################################################

locals {
  common_tags = {
    Project     = var.project
    Environment = var.environment
    ManagedBy   = "Terraform"
  }
}

# ---------------------------------------------------------------------------
# SNS Topic for Ops Alerts
# ---------------------------------------------------------------------------

resource "aws_sns_topic" "ops_alerts" {
  name              = "${var.project}-ops-alerts"
  kms_master_key_id = "alias/aws/sns"

  tags = merge(
    local.common_tags,
    {
      Name = "${var.project}-ops-alerts"
    }
  )
}

resource "aws_sns_topic_policy" "ops_alerts" {
  arn = aws_sns_topic.ops_alerts.arn

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Principal = {
          Service = [
            "cloudwatch.amazonaws.com",
            "budgets.amazonaws.com",
            "cloudtrail.amazonaws.com",
          ]
        }
        Action   = "SNS:Publish"
        Resource = aws_sns_topic.ops_alerts.arn
      },
    ]
  })
}

# ---------------------------------------------------------------------------
# Email Subscriptions
# ---------------------------------------------------------------------------

resource "aws_sns_topic_subscription" "ops_alerts_email" {
  for_each = toset(var.alert_email_addresses)

  topic_arn = aws_sns_topic.ops_alerts.arn
  protocol  = "email"
  endpoint  = each.value
}

# ---------------------------------------------------------------------------
# SMS Subscriptions (optional)
# ---------------------------------------------------------------------------

resource "aws_sns_topic_subscription" "ops_alerts_sms" {
  for_each = var.enable_sms_alerts ? toset(var.alert_phone_numbers) : toset([])

  topic_arn = aws_sns_topic.ops_alerts.arn
  protocol  = "sms"
  endpoint  = each.value
}

# ---------------------------------------------------------------------------
# Critical Alerts Topic (strict severity-based routing)
# ---------------------------------------------------------------------------

resource "aws_sns_topic" "critical_alerts" {
  name              = "${var.project}-critical-alerts"
  kms_master_key_id = "alias/aws/sns"

  tags = merge(
    local.common_tags,
    {
      Name = "${var.project}-critical-alerts"
    }
  )
}

resource "aws_sns_topic_policy" "critical_alerts" {
  arn = aws_sns_topic.critical_alerts.arn

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Principal = {
          Service = [
            "cloudwatch.amazonaws.com",
            "budgets.amazonaws.com",
          ]
        }
        Action   = "SNS:Publish"
        Resource = aws_sns_topic.critical_alerts.arn
      },
    ]
  })
}

# Critical alerts: SMS only (stricter)
resource "aws_sns_topic_subscription" "critical_alerts_sms" {
  for_each = toset(var.critical_alert_phone_numbers)

  topic_arn = aws_sns_topic.critical_alerts.arn
  protocol  = "sms"
  endpoint  = each.value
}

# ---------------------------------------------------------------------------
# Optional Slack Integration via Lambda
# ---------------------------------------------------------------------------

# Note: Slack integration requires a Lambda function to transform SNS
# messages into Slack format and post to a webhook. This module provides
# the SNS topic; the Lambda function and webhook management are outside
# the scope of this module (see README for integration instructions).

resource "aws_sns_topic" "slack_notifications" {
  count             = var.enable_slack_integration ? 1 : 0
  name              = "${var.project}-slack-notifications"
  kms_master_key_id = "alias/aws/sns"

  tags = merge(
    local.common_tags,
    {
      Name = "${var.project}-slack-notifications"
    }
  )
}

# ---------------------------------------------------------------------------
# Optional PagerDuty Integration
# ---------------------------------------------------------------------------

# Note: PagerDuty integration requires a PagerDuty service and integration key.
# Create this topic if you want to route critical alerts to PagerDuty.

resource "aws_sns_topic" "pagerduty_alerts" {
  count             = var.enable_pagerduty_integration ? 1 : 0
  name              = "${var.project}-pagerduty-alerts"
  kms_master_key_id = "alias/aws/sns"

  tags = merge(
    local.common_tags,
    {
      Name = "${var.project}-pagerduty-alerts"
    }
  )
}

resource "aws_sns_topic_subscription" "pagerduty_alerts" {
  count     = var.enable_pagerduty_integration && var.pagerduty_webhook_url != "" ? 1 : 0
  topic_arn = aws_sns_topic.pagerduty_alerts[0].arn
  protocol  = "https"
  endpoint  = var.pagerduty_webhook_url
}

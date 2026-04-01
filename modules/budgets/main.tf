###############################################################################
# Budgets Module — Cost Control
#
# AWS Budgets with SNS alerts at 50%, 80%, and 100% of monthly threshold.
# Prevents surprise bills in shared AWS accounts.
###############################################################################

locals {
  common_tags = {
    Project     = var.project
    Environment = var.environment
    ManagedBy   = "Terraform"
  }
}

# ---------------------------------------------------------------------------
# Monthly Budget Alert
# ---------------------------------------------------------------------------

resource "aws_budgets_budget" "monthly_total" {
  name         = "${var.project}-monthly-budget"
  budget_type  = "COST"
  limit_amount = var.monthly_budget_limit
  limit_unit   = "USD"
  time_unit    = "MONTHLY"

  # Alert at 50% of budget
  notification {
    comparison_operator        = "GREATER_THAN"
    threshold                  = 50
    threshold_type             = "PERCENTAGE"
    notification_type          = "ACTUAL"
    subscriber_email_addresses = var.alert_email_addresses
  }

  # Alert at 80% of budget
  notification {
    comparison_operator        = "GREATER_THAN"
    threshold                  = 80
    threshold_type             = "PERCENTAGE"
    notification_type          = "ACTUAL"
    subscriber_email_addresses = var.alert_email_addresses
  }

  # Alert at 100% of budget
  notification {
    comparison_operator        = "GREATER_THAN"
    threshold                  = 100
    threshold_type             = "PERCENTAGE"
    notification_type          = "ACTUAL"
    subscriber_email_addresses = var.alert_email_addresses
  }

  # Forecasted to exceed budget
  notification {
    comparison_operator        = "GREATER_THAN"
    threshold                  = 100
    threshold_type             = "PERCENTAGE"
    notification_type          = "FORECASTED"
    subscriber_email_addresses = var.alert_email_addresses
  }
}

# ---------------------------------------------------------------------------
# Safety Net Budget (hard limit to catch runaway costs)
# ---------------------------------------------------------------------------

resource "aws_budgets_budget" "safety_net" {
  count        = var.enable_safety_net_budget ? 1 : 0
  name         = "${var.project}-safety-net-budget"
  budget_type  = "COST"
  limit_amount = var.safety_net_limit
  limit_unit   = "USD"
  time_unit    = "MONTHLY"

  # Alert at 80% of safety net
  notification {
    comparison_operator        = "GREATER_THAN"
    threshold                  = 80
    threshold_type             = "PERCENTAGE"
    notification_type          = "ACTUAL"
    subscriber_email_addresses = var.alert_email_addresses
  }

  # Critical alert at 100% of safety net
  notification {
    comparison_operator        = "GREATER_THAN"
    threshold                  = 100
    threshold_type             = "PERCENTAGE"
    notification_type          = "ACTUAL"
    subscriber_email_addresses = var.alert_email_addresses
  }

  # Forecasted to exceed safety net
  notification {
    comparison_operator        = "GREATER_THAN"
    threshold                  = 100
    threshold_type             = "PERCENTAGE"
    notification_type          = "FORECASTED"
    subscriber_email_addresses = var.alert_email_addresses
  }
}

# ---------------------------------------------------------------------------
# Service-Specific Budgets (optional)
# ---------------------------------------------------------------------------

# Lambda budget
resource "aws_budgets_budget" "service_lambda" {
  count        = var.enable_service_budgets ? 1 : 0
  name         = "${var.project}-lambda-budget"
  budget_type  = "COST"
  limit_amount = var.lambda_budget_limit
  limit_unit   = "USD"
  time_unit    = "MONTHLY"

  cost_filter {
    name   = "Service"
    values = ["AWS Lambda"]
  }

  notification {
    comparison_operator        = "GREATER_THAN"
    threshold                  = 80
    threshold_type             = "PERCENTAGE"
    notification_type          = "ACTUAL"
    subscriber_email_addresses = var.alert_email_addresses
  }
}

# DynamoDB budget
resource "aws_budgets_budget" "service_dynamodb" {
  count        = var.enable_service_budgets ? 1 : 0
  name         = "${var.project}-dynamodb-budget"
  budget_type  = "COST"
  limit_amount = var.dynamodb_budget_limit
  limit_unit   = "USD"
  time_unit    = "MONTHLY"

  cost_filter {
    name   = "Service"
    values = ["Amazon DynamoDB"]
  }

  notification {
    comparison_operator        = "GREATER_THAN"
    threshold                  = 80
    threshold_type             = "PERCENTAGE"
    notification_type          = "ACTUAL"
    subscriber_email_addresses = var.alert_email_addresses
  }
}

# S3 budget
resource "aws_budgets_budget" "service_s3" {
  count        = var.enable_service_budgets ? 1 : 0
  name         = "${var.project}-s3-budget"
  budget_type  = "COST"
  limit_amount = var.s3_budget_limit
  limit_unit   = "USD"
  time_unit    = "MONTHLY"

  cost_filter {
    name   = "Service"
    values = ["Amazon Simple Storage Service"]
  }

  notification {
    comparison_operator        = "GREATER_THAN"
    threshold                  = 80
    threshold_type             = "PERCENTAGE"
    notification_type          = "ACTUAL"
    subscriber_email_addresses = var.alert_email_addresses
  }
}

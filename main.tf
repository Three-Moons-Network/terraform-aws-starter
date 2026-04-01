###############################################################################
# terraform-aws-starter
#
# Day-one AWS account foundation — VPC, IAM baseline, CloudTrail, budgets,
# and alerting. Deploys production-ready security and observability controls.
###############################################################################

terraform {
  required_version = ">= 1.5"

  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
  }
}

provider "aws" {
  region = var.region

  default_tags {
    tags = {
      Project     = var.project
      Environment = var.environment
      ManagedBy   = "Terraform"
      CreatedAt   = timestamp()
    }
  }
}

# ---------------------------------------------------------------------------
# VPC
# ---------------------------------------------------------------------------

module "vpc" {
  source = "./modules/vpc"

  vpc_cidr                 = var.vpc_cidr
  environment              = var.environment
  project                  = var.project
  enable_nat_gateway       = var.enable_nat_gateway
  enable_flow_logs         = var.enable_flow_logs
  flow_logs_retention_days = var.flow_logs_retention_days
}

# ---------------------------------------------------------------------------
# IAM Baseline
# ---------------------------------------------------------------------------

module "iam_baseline" {
  source = "./modules/iam-baseline"

  project     = var.project
  environment = var.environment
}

# ---------------------------------------------------------------------------
# Alerting (SNS Topics)
# ---------------------------------------------------------------------------

module "alerting" {
  source = "./modules/alerting"

  project                      = var.project
  environment                  = var.environment
  alert_email_addresses        = var.alert_email_addresses
  alert_phone_numbers          = var.alert_phone_numbers
  enable_sms_alerts            = var.enable_sms_alerts
  critical_alert_phone_numbers = var.critical_alert_phone_numbers
  enable_slack_integration     = var.enable_slack_integration
  enable_pagerduty_integration = var.enable_pagerduty_integration
  pagerduty_webhook_url        = var.pagerduty_webhook_url
}

# ---------------------------------------------------------------------------
# CloudTrail
# ---------------------------------------------------------------------------

module "cloudtrail" {
  source = "./modules/cloudtrail"

  project                       = var.project
  environment                   = var.environment
  cloudwatch_log_retention_days = var.cloudtrail_log_retention_days
  alarm_sns_topic_arns          = [module.alerting.ops_alerts_topic_arn]
}

# ---------------------------------------------------------------------------
# Budgets
# ---------------------------------------------------------------------------

module "budgets" {
  source = "./modules/budgets"

  project                  = var.project
  environment              = var.environment
  monthly_budget_limit     = var.monthly_budget_limit
  alert_email_addresses    = var.alert_email_addresses
  enable_safety_net_budget = var.enable_safety_net_budget
  safety_net_limit         = var.safety_net_limit
  enable_service_budgets   = var.enable_service_budgets
  lambda_budget_limit      = var.lambda_budget_limit
  dynamodb_budget_limit    = var.dynamodb_budget_limit
  s3_budget_limit          = var.s3_budget_limit
}

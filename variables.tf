variable "region" {
  description = "AWS region"
  type        = string
  default     = "us-east-1"
}

variable "project" {
  description = "Project name for tagging and naming"
  type        = string
}

variable "environment" {
  description = "Environment name (dev, staging, prod)"
  type        = string
}

# ---------------------------------------------------------------------------
# VPC Configuration
# ---------------------------------------------------------------------------

variable "vpc_cidr" {
  description = "CIDR block for VPC (e.g., 10.0.0.0/16)"
  type        = string
  default     = "10.0.0.0/16"
}

variable "enable_nat_gateway" {
  description = "Enable NAT gateway for private subnet egress (default: false for cost)"
  type        = bool
  default     = false
}

variable "enable_flow_logs" {
  description = "Enable VPC flow logs to CloudWatch (default: false)"
  type        = bool
  default     = false
}

variable "flow_logs_retention_days" {
  description = "CloudWatch log retention for VPC flow logs"
  type        = number
  default     = 7
}

# ---------------------------------------------------------------------------
# Alerting Configuration
# ---------------------------------------------------------------------------

variable "alert_email_addresses" {
  description = "Email addresses for operations alerts (required)"
  type        = list(string)
}

variable "alert_phone_numbers" {
  description = "Phone numbers for SMS alerts (E.164 format: +1234567890)"
  type        = list(string)
  default     = []
}

variable "enable_sms_alerts" {
  description = "Enable SMS alerts"
  type        = bool
  default     = false
}

variable "critical_alert_phone_numbers" {
  description = "Phone numbers for critical SMS alerts only"
  type        = list(string)
  default     = []
}

variable "enable_slack_integration" {
  description = "Enable Slack integration (requires separate Lambda)"
  type        = bool
  default     = false
}

variable "enable_pagerduty_integration" {
  description = "Enable PagerDuty integration"
  type        = bool
  default     = false
}

variable "pagerduty_webhook_url" {
  description = "PagerDuty webhook URL"
  type        = string
  default     = ""
  sensitive   = true
}

# ---------------------------------------------------------------------------
# CloudTrail Configuration
# ---------------------------------------------------------------------------

variable "cloudtrail_log_retention_days" {
  description = "CloudWatch log retention for CloudTrail logs in days"
  type        = number
  default     = 30
}

# ---------------------------------------------------------------------------
# Budget Configuration
# ---------------------------------------------------------------------------

variable "monthly_budget_limit" {
  description = "Monthly budget limit in USD (e.g., 100)"
  type        = string
}

variable "enable_safety_net_budget" {
  description = "Enable safety net budget (default: true)"
  type        = bool
  default     = true
}

variable "safety_net_limit" {
  description = "Hard limit for safety net budget in USD"
  type        = string
  default     = "500"
}

variable "enable_service_budgets" {
  description = "Enable per-service budgets (Lambda, DynamoDB, S3)"
  type        = bool
  default     = false
}

variable "lambda_budget_limit" {
  description = "Monthly budget limit for Lambda in USD"
  type        = string
  default     = "50"
}

variable "dynamodb_budget_limit" {
  description = "Monthly budget limit for DynamoDB in USD"
  type        = string
  default     = "50"
}

variable "s3_budget_limit" {
  description = "Monthly budget limit for S3 in USD"
  type        = string
  default     = "50"
}

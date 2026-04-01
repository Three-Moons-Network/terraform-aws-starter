variable "project" {
  description = "Project name for naming resources"
  type        = string
}

variable "environment" {
  description = "Environment name (dev, staging, prod)"
  type        = string
}

variable "monthly_budget_limit" {
  description = "Monthly budget limit in USD"
  type        = string
}

variable "alert_email_addresses" {
  description = "Email addresses to receive budget alerts"
  type        = list(string)
}

variable "enable_safety_net_budget" {
  description = "Enable a safety net budget as a hard limit"
  type        = bool
  default     = true
}

variable "safety_net_limit" {
  description = "Hard limit for safety net budget in USD"
  type        = string
  default     = "500"
}

variable "enable_service_budgets" {
  description = "Enable per-service budgets for Lambda, DynamoDB, S3"
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

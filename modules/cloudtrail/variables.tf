variable "project" {
  description = "Project name for naming resources"
  type        = string
}

variable "environment" {
  description = "Environment name (dev, staging, prod)"
  type        = string
}

variable "cloudwatch_log_retention_days" {
  description = "CloudWatch log retention for CloudTrail logs in days"
  type        = number
  default     = 30
}

variable "alarm_sns_topic_arns" {
  description = "List of SNS topic ARNs to send alarms to"
  type        = list(string)
  default     = []
}

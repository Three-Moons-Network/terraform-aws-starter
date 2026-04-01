variable "project" {
  description = "Project name for naming resources"
  type        = string
}

variable "environment" {
  description = "Environment name (dev, staging, prod)"
  type        = string
}

variable "alert_email_addresses" {
  description = "Email addresses to receive operations alerts"
  type        = list(string)
}

variable "alert_phone_numbers" {
  description = "Phone numbers to receive SMS alerts (E.164 format: +1234567890)"
  type        = list(string)
  default     = []
}

variable "enable_sms_alerts" {
  description = "Enable SMS alerts for operations alerts"
  type        = bool
  default     = false
}

variable "critical_alert_phone_numbers" {
  description = "Phone numbers for critical SMS alerts only (E.164 format: +1234567890)"
  type        = list(string)
  default     = []
}

variable "enable_slack_integration" {
  description = "Enable Slack integration topic (requires separate Lambda for message formatting)"
  type        = bool
  default     = false
}

variable "enable_pagerduty_integration" {
  description = "Enable PagerDuty integration topic"
  type        = bool
  default     = false
}

variable "pagerduty_webhook_url" {
  description = "PagerDuty webhook URL for alert integration (required if pagerduty_enabled = true)"
  type        = string
  default     = ""
  sensitive   = true
}

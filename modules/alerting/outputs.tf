output "ops_alerts_topic_arn" {
  description = "ARN of the ops alerts SNS topic"
  value       = aws_sns_topic.ops_alerts.arn
}

output "ops_alerts_topic_name" {
  description = "Name of the ops alerts SNS topic"
  value       = aws_sns_topic.ops_alerts.name
}

output "critical_alerts_topic_arn" {
  description = "ARN of the critical alerts SNS topic"
  value       = aws_sns_topic.critical_alerts.arn
}

output "critical_alerts_topic_name" {
  description = "Name of the critical alerts SNS topic"
  value       = aws_sns_topic.critical_alerts.name
}

output "slack_notifications_topic_arn" {
  description = "ARN of the Slack notifications SNS topic (if enabled)"
  value       = try(aws_sns_topic.slack_notifications[0].arn, null)
}

output "pagerduty_alerts_topic_arn" {
  description = "ARN of the PagerDuty alerts SNS topic (if enabled)"
  value       = try(aws_sns_topic.pagerduty_alerts[0].arn, null)
}

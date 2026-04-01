output "cloudtrail_id" {
  description = "CloudTrail trail ID"
  value       = aws_cloudtrail.this.id
}

output "cloudtrail_s3_bucket_name" {
  description = "S3 bucket name for CloudTrail logs"
  value       = aws_s3_bucket.cloudtrail.id
}

output "cloudwatch_log_group_name" {
  description = "CloudWatch log group name for CloudTrail logs"
  value       = aws_cloudwatch_log_group.cloudtrail.name
}

output "root_account_usage_alarm_name" {
  description = "Alarm name for root account usage"
  value       = aws_cloudwatch_metric_alarm.root_account_usage.alarm_name
}

output "unauthorized_api_calls_alarm_name" {
  description = "Alarm name for unauthorized API calls"
  value       = aws_cloudwatch_metric_alarm.unauthorized_api_calls.alarm_name
}

output "iam_policy_changes_alarm_name" {
  description = "Alarm name for IAM policy changes"
  value       = aws_cloudwatch_metric_alarm.iam_policy_changes.alarm_name
}

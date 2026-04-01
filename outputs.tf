output "vpc_id" {
  description = "VPC ID"
  value       = module.vpc.vpc_id
}

output "vpc_cidr" {
  description = "VPC CIDR block"
  value       = module.vpc.vpc_cidr
}

output "public_subnet_ids" {
  description = "Public subnet IDs"
  value       = module.vpc.public_subnet_ids
}

output "private_subnet_ids" {
  description = "Private subnet IDs"
  value       = module.vpc.private_subnet_ids
}

output "availability_zones" {
  description = "Availability zones used"
  value       = module.vpc.availability_zones
}

output "admin_group_name" {
  description = "Admin IAM group name"
  value       = module.iam_baseline.admin_group_name
}

output "developer_group_name" {
  description = "Developer IAM group name"
  value       = module.iam_baseline.developer_group_name
}

output "read_only_group_name" {
  description = "Read-only IAM group name"
  value       = module.iam_baseline.read_only_group_name
}

output "cloudtrail_s3_bucket_name" {
  description = "S3 bucket for CloudTrail logs"
  value       = module.cloudtrail.cloudtrail_s3_bucket_name
}

output "cloudtrail_cloudwatch_log_group" {
  description = "CloudWatch log group for CloudTrail"
  value       = module.cloudtrail.cloudwatch_log_group_name
}

output "ops_alerts_topic_arn" {
  description = "SNS topic ARN for operations alerts"
  value       = module.alerting.ops_alerts_topic_arn
}

output "critical_alerts_topic_arn" {
  description = "SNS topic ARN for critical alerts"
  value       = module.alerting.critical_alerts_topic_arn
}

output "main_budget_name" {
  description = "Main monthly budget name"
  value       = module.budgets.main_budget_name
}

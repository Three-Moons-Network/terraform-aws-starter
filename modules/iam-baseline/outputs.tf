output "admin_group_name" {
  description = "Name of the admin IAM group"
  value       = aws_iam_group.admin.name
}

output "developer_group_name" {
  description = "Name of the developer IAM group"
  value       = aws_iam_group.developer.name
}

output "read_only_group_name" {
  description = "Name of the read-only IAM group"
  value       = aws_iam_group.read_only.name
}

output "enforce_mfa_policy_arn" {
  description = "ARN of the MFA enforcement policy"
  value       = aws_iam_policy.enforce_mfa.arn
}

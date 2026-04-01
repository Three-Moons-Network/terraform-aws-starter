###############################################################################
# CloudTrail Module — Audit Logging
#
# Multi-region CloudTrail trail with encrypted S3 backend and CloudWatch
# Logs integration for real-time alerting on account activity.
###############################################################################

locals {
  common_tags = {
    Project     = var.project
    Environment = var.environment
    ManagedBy   = "Terraform"
  }
}

# ---------------------------------------------------------------------------
# S3 Bucket for CloudTrail Logs
# ---------------------------------------------------------------------------

resource "aws_s3_bucket" "cloudtrail" {
  bucket = "${var.project}-cloudtrail-logs-${data.aws_caller_identity.current.account_id}"

  tags = merge(
    local.common_tags,
    {
      Name = "${var.project}-cloudtrail-logs"
    }
  )
}

data "aws_caller_identity" "current" {}

resource "aws_s3_bucket_versioning" "cloudtrail" {
  bucket = aws_s3_bucket.cloudtrail.id

  versioning_configuration {
    status = "Enabled"
  }
}

resource "aws_s3_bucket_server_side_encryption_configuration" "cloudtrail" {
  bucket = aws_s3_bucket.cloudtrail.id

  rule {
    apply_server_side_encryption_by_default {
      sse_algorithm = "AES256"
    }
  }
}

resource "aws_s3_bucket_public_access_block" "cloudtrail" {
  bucket = aws_s3_bucket.cloudtrail.id

  block_public_acls       = true
  block_public_policy     = true
  ignore_public_acls      = true
  restrict_public_buckets = true
}

resource "aws_s3_bucket_policy" "cloudtrail" {
  bucket = aws_s3_bucket.cloudtrail.id
  policy = data.aws_iam_policy_document.cloudtrail_bucket.json
}

data "aws_iam_policy_document" "cloudtrail_bucket" {
  statement {
    sid    = "AWSCloudTrailAclCheck"
    effect = "Allow"
    principals = {
      Service = "cloudtrail.amazonaws.com"
    }
    actions   = ["s3:GetBucketAcl"]
    resources = [aws_s3_bucket.cloudtrail.arn]
  }

  statement {
    sid    = "AWSCloudTrailWrite"
    effect = "Allow"
    principals = {
      Service = "cloudtrail.amazonaws.com"
    }
    actions = [
      "s3:PutObject",
    ]
    resources = ["${aws_s3_bucket.cloudtrail.arn}/*"]
    condition {
      test     = "StringEquals"
      variable = "s3:x-amz-acl"
      values   = ["bucket-owner-full-control"]
    }
  }
}

# Lifecycle rule: transition to Glacier after 90 days, delete after 2 years
resource "aws_s3_bucket_lifecycle_configuration" "cloudtrail" {
  bucket = aws_s3_bucket.cloudtrail.id

  rule {
    id     = "archive-cloudtrail-logs"
    status = "Enabled"

    transition {
      days          = 90
      storage_class = "GLACIER"
    }

    expiration {
      days = 730
    }
  }
}

# ---------------------------------------------------------------------------
# CloudWatch Log Group for CloudTrail
# ---------------------------------------------------------------------------

resource "aws_cloudwatch_log_group" "cloudtrail" {
  name              = "/aws/cloudtrail/${var.project}"
  retention_in_days = var.cloudwatch_log_retention_days

  tags = merge(
    local.common_tags,
    {
      Name = "${var.project}-cloudtrail-logs"
    }
  )
}

# IAM role for CloudTrail to write to CloudWatch Logs
resource "aws_iam_role" "cloudtrail_cloudwatch" {
  name = "${var.project}-cloudtrail-cloudwatch"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Action = "sts:AssumeRole"
      Effect = "Allow"
      Principal = {
        Service = "cloudtrail.amazonaws.com"
      }
    }]
  })

  tags = local.common_tags
}

resource "aws_iam_role_policy" "cloudtrail_cloudwatch" {
  name = "${var.project}-cloudtrail-cloudwatch"
  role = aws_iam_role.cloudtrail_cloudwatch.id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Action = [
        "logs:CreateLogStream",
        "logs:PutLogEvents",
      ]
      Effect   = "Allow"
      Resource = "${aws_cloudwatch_log_group.cloudtrail.arn}:*"
    }]
  })
}

# ---------------------------------------------------------------------------
# CloudTrail — Multi-Region Trail
# ---------------------------------------------------------------------------

resource "aws_cloudtrail" "this" {
  name                          = "${var.project}-trail"
  s3_bucket_name                = aws_s3_bucket.cloudtrail.id
  include_global_service_events = true
  is_multi_region_trail         = true
  enable_log_file_validation    = true
  cloud_watch_logs_group_arn    = "${aws_cloudwatch_log_group.cloudtrail.arn}:*"
  cloud_watch_logs_role_arn     = aws_iam_role.cloudtrail_cloudwatch.arn
  depends_on                    = [aws_s3_bucket_policy.cloudtrail]

  event_selector {
    read_write_type           = "All"
    include_management_events = true

    data_resource {
      type   = "AWS::S3::Object"
      values = ["arn:aws:s3:::*"]
    }

    data_resource {
      type   = "AWS::Lambda::Function"
      values = ["arn:aws:lambda:*:*:function/*"]
    }
  }

  insight_selector {
    insight_type = "ApiCallRateInsight"
  }

  tags = merge(
    local.common_tags,
    {
      Name = "${var.project}-trail"
    }
  )
}

# ---------------------------------------------------------------------------
# CloudWatch Alarms for Suspicious Activity
# ---------------------------------------------------------------------------

resource "aws_cloudwatch_log_group" "root_account_usage" {
  name              = "/aws/cloudtrail/${var.project}-root-usage"
  retention_in_days = var.cloudwatch_log_retention_days

  tags = merge(
    local.common_tags,
    {
      Name = "${var.project}-root-usage-alerts"
    }
  )
}

resource "aws_cloudwatch_log_metric_filter" "root_account_usage" {
  name           = "${var.project}-root-account-usage"
  log_group_name = aws_cloudwatch_log_group.cloudtrail.name
  filter_pattern = "{ $.userIdentity.type = \"Root\" && $.userIdentity.invokedBy NOT EXISTS && $.eventType != \"AwsServiceEvent\" }"

  metric_transformation {
    name      = "${var.project}-RootAccountUsage"
    namespace = "${var.project}/Security"
    value     = "1"
  }
}

resource "aws_cloudwatch_metric_alarm" "root_account_usage" {
  alarm_name          = "${var.project}-root-account-usage"
  comparison_operator = "GreaterThanOrEqualToThreshold"
  evaluation_periods  = 1
  metric_name         = "${var.project}-RootAccountUsage"
  namespace           = "${var.project}/Security"
  period              = 300
  statistic           = "Sum"
  threshold           = 1
  alarm_description   = "Root account activity detected"
  alarm_actions       = var.alarm_sns_topic_arns
  treat_missing_data  = "notBreaching"
}

# Unauthorized API calls
resource "aws_cloudwatch_log_metric_filter" "unauthorized_api_calls" {
  name           = "${var.project}-unauthorized-api-calls"
  log_group_name = aws_cloudwatch_log_group.cloudtrail.name
  filter_pattern = "{ ($.errorCode = \"*UnauthorizedOperation\") || ($.errorCode = \"AccessDenied*\") }"

  metric_transformation {
    name      = "${var.project}-UnauthorizedAPICallsMetric"
    namespace = "${var.project}/Security"
    value     = "1"
  }
}

resource "aws_cloudwatch_metric_alarm" "unauthorized_api_calls" {
  alarm_name          = "${var.project}-unauthorized-api-calls"
  comparison_operator = "GreaterThanOrEqualToThreshold"
  evaluation_periods  = 1
  metric_name         = "${var.project}-UnauthorizedAPICallsMetric"
  namespace           = "${var.project}/Security"
  period              = 300
  statistic           = "Sum"
  threshold           = 5
  alarm_description   = "Unauthorized API calls detected (threshold: 5 in 5 min)"
  alarm_actions       = var.alarm_sns_topic_arns
  treat_missing_data  = "notBreaching"
}

# IAM policy changes
resource "aws_cloudwatch_log_metric_filter" "iam_policy_changes" {
  name           = "${var.project}-iam-policy-changes"
  log_group_name = aws_cloudwatch_log_group.cloudtrail.name
  filter_pattern = "{($.eventName=DeleteGroupPolicy)||($.eventName=DeleteRolePolicy)||($.eventName=DeleteUserPolicy)||($.eventName=PutGroupPolicy)||($.eventName=PutRolePolicy)||($.eventName=PutUserPolicy)||($.eventName=CreatePolicy)||($.eventName=DeletePolicy)||($.eventName=CreatePolicyVersion)||($.eventName=DeletePolicyVersion)||($.eventName=AttachRolePolicy)||($.eventName=DetachRolePolicy)||($.eventName=AttachUserPolicy)||($.eventName=DetachUserPolicy)||($.eventName=AttachGroupPolicy)||($.eventName=DetachGroupPolicy)}"

  metric_transformation {
    name      = "${var.project}-IAMPolicyChangesMetric"
    namespace = "${var.project}/Security"
    value     = "1"
  }
}

resource "aws_cloudwatch_metric_alarm" "iam_policy_changes" {
  alarm_name          = "${var.project}-iam-policy-changes"
  comparison_operator = "GreaterThanOrEqualToThreshold"
  evaluation_periods  = 1
  metric_name         = "${var.project}-IAMPolicyChangesMetric"
  namespace           = "${var.project}/Security"
  period              = 300
  statistic           = "Sum"
  threshold           = 1
  alarm_description   = "IAM policy change detected"
  alarm_actions       = var.alarm_sns_topic_arns
  treat_missing_data  = "notBreaching"
}

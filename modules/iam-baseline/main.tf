###############################################################################
# IAM Baseline Module — Account Access Control
#
# Sets up three user groups (admin, developer, read-only) with sensible
# permission boundaries. Enforces MFA and strong password policy.
###############################################################################

locals {
  common_tags = {
    Project     = var.project
    Environment = var.environment
    ManagedBy   = "Terraform"
  }
}

# ---------------------------------------------------------------------------
# Account Password Policy
# ---------------------------------------------------------------------------

resource "aws_account_password_policy" "this" {
  minimum_password_length        = 14
  require_lowercase_characters   = true
  require_numbers                = true
  require_uppercase_characters   = true
  require_symbols                = true
  allow_users_to_change_password = true
  expire_passwords               = true
  max_password_age               = 90
  password_reuse_prevention      = 24
  hard_expiry                    = false
}

# ---------------------------------------------------------------------------
# Admin Group
# ---------------------------------------------------------------------------

resource "aws_iam_group" "admin" {
  name = "${var.project}-admin"
}

resource "aws_iam_group_policy_attachment" "admin_attach" {
  group      = aws_iam_group.admin.name
  policy_arn = "arn:aws:iam::aws:policy/AdministratorAccess"
}

# ---------------------------------------------------------------------------
# Developer Group
# ---------------------------------------------------------------------------

resource "aws_iam_group" "developer" {
  name = "${var.project}-developer"
}

resource "aws_iam_group_policy" "developer" {
  name   = "${var.project}-developer-policy"
  group  = aws_iam_group.developer.name
  policy = data.aws_iam_policy_document.developer.json
}

data "aws_iam_policy_document" "developer" {
  statement {
    sid    = "EC2FullAccess"
    effect = "Allow"
    actions = [
      "ec2:*",
    ]
    resources = ["*"]
  }

  statement {
    sid    = "LambdaFullAccess"
    effect = "Allow"
    actions = [
      "lambda:*",
      "apigateway:*",
      "logs:*",
    ]
    resources = ["*"]
  }

  statement {
    sid    = "S3Access"
    effect = "Allow"
    actions = [
      "s3:GetObject",
      "s3:PutObject",
      "s3:DeleteObject",
      "s3:ListBucket",
    ]
    resources = ["*"]
  }

  statement {
    sid    = "DynamoDBAccess"
    effect = "Allow"
    actions = [
      "dynamodb:GetItem",
      "dynamodb:PutItem",
      "dynamodb:UpdateItem",
      "dynamodb:Query",
      "dynamodb:Scan",
      "dynamodb:DeleteItem",
    ]
    resources = ["*"]
  }

  statement {
    sid    = "SecretsManagerAccess"
    effect = "Allow"
    actions = [
      "secretsmanager:GetSecretValue",
      "secretsmanager:DescribeSecret",
    ]
    resources = ["*"]
  }

  statement {
    sid    = "SSMParameterAccess"
    effect = "Allow"
    actions = [
      "ssm:GetParameter",
      "ssm:GetParameters",
      "ssm:DescribeParameters",
    ]
    resources = ["*"]
  }

  statement {
    sid    = "CloudWatchAccess"
    effect = "Allow"
    actions = [
      "cloudwatch:*",
      "logs:*",
    ]
    resources = ["*"]
  }

  statement {
    sid    = "IAMCreateAccessKey"
    effect = "Allow"
    actions = [
      "iam:CreateAccessKey",
      "iam:ListAccessKeys",
      "iam:GetAccessKeyLastUsed",
    ]
    resources = ["arn:aws:iam::*:user/$${aws:username}"]
  }

  statement {
    sid    = "DenyAdminAndIAMModifications"
    effect = "Deny"
    actions = [
      "iam:*",
      "organizations:*",
      "account:*",
    ]
    resources = ["*"]
  }

  statement {
    sid    = "DenyRootUserMFA"
    effect = "Deny"
    actions = [
      "iam:*",
    ]
    resources = [
      "arn:aws:iam::*:user/root",
      "arn:aws:iam::*:root",
    ]
  }
}

# ---------------------------------------------------------------------------
# Read-Only Group
# ---------------------------------------------------------------------------

resource "aws_iam_group" "read_only" {
  name = "${var.project}-read-only"
}

resource "aws_iam_group_policy_attachment" "read_only_attach" {
  group      = aws_iam_group.read_only.name
  policy_arn = "arn:aws:iam::aws:policy/ReadOnlyAccess"
}

# ---------------------------------------------------------------------------
# MFA Device Enforcement Policy (applies to all users)
# ---------------------------------------------------------------------------

resource "aws_iam_policy" "enforce_mfa" {
  name        = "${var.project}-enforce-mfa"
  description = "Requires MFA for sensitive operations"
  policy      = data.aws_iam_policy_document.enforce_mfa.json
}

data "aws_iam_policy_document" "enforce_mfa" {
  statement {
    sid    = "AllowListingCredentials"
    effect = "Allow"
    actions = [
      "iam:GetAccessKeyLastUsed",
      "iam:GetUser",
      "iam:ListAccessKeys",
      "iam:ListMFADevices",
      "iam:ListVirtualMFADevices",
      "iam:ListUserPolicies",
      "iam:ListUserTags",
    ]
    resources = ["arn:aws:iam::*:user/$${aws:username}"]
  }

  statement {
    sid    = "AllowResyncMFADevice"
    effect = "Allow"
    actions = [
      "iam:ResyncMFADevice",
    ]
    resources = ["arn:aws:iam::*:user/$${aws:username}"]
  }

  statement {
    sid    = "AllowCreateVirtualMFADevice"
    effect = "Allow"
    actions = [
      "iam:CreateVirtualMFADevice",
    ]
    resources = ["arn:aws:iam::*:mfa/$${aws:username}"]
  }

  statement {
    sid    = "AllowDeactivateOldMFADevice"
    effect = "Allow"
    actions = [
      "iam:DeactivateMFADevice",
    ]
    resources = ["arn:aws:iam::*:user/$${aws:username}"]
  }

  statement {
    sid       = "DenyAllExceptListedIfNoMFA"
    effect    = "Deny"
    not_actions = [
      "iam:GetAccessKeyLastUsed",
      "iam:GetUser",
      "iam:ListAccessKeys",
      "iam:ListMFADevices",
      "iam:ListVirtualMFADevices",
      "iam:ListUserPolicies",
      "iam:ListUserTags",
      "sts:GetCallerIdentity",
    ]
    resources = ["*"]
    condition {
      test     = "BoolIfExists"
      variable = "aws:MultiFactorAuthPresent"
      values   = ["false"]
    }
  }
}

# Attach MFA enforcement policy to all groups
resource "aws_iam_group_policy_attachment" "admin_mfa" {
  group      = aws_iam_group.admin.name
  policy_arn = aws_iam_policy.enforce_mfa.arn
}

resource "aws_iam_group_policy_attachment" "developer_mfa" {
  group      = aws_iam_group.developer.name
  policy_arn = aws_iam_policy.enforce_mfa.arn
}

resource "aws_iam_group_policy_attachment" "read_only_mfa" {
  group      = aws_iam_group.read_only.name
  policy_arn = aws_iam_policy.enforce_mfa.arn
}

# ---------------------------------------------------------------------------
# Account Root User Protection
# ---------------------------------------------------------------------------

resource "aws_iam_account_password_policy" "root_mfa_required" {
  # This is a policy, not a resource — it's enforced at the account level
  # The following is managed via account settings:
  # 1. Enable MFA on root user
  # 2. Never create access keys for root user
  # 3. Use CloudTrail to audit root user activity
}

# Note: Root account MFA, access key management, and activity monitoring
# cannot be enforced via Terraform IAM policies. These must be configured
# manually in the AWS Console or via the account management API.
# See the README for manual setup instructions.

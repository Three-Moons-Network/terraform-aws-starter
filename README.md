# Terraform AWS Starter

Day-one AWS account foundation for any client. Deploys a secure, observable, and cost-controlled baseline: VPC with public/private subnets, IAM groups with MFA enforcement, CloudTrail audit logging, budget alerts, and operational alerting via SNS.

Built as a reference implementation by [Three Moons Network](https://threemoonsnetwork.net) — an AI consulting practice helping small businesses deploy production-grade infrastructure.

## Architecture

```
┌─────────────────────────────────────────────────────────────────────┐
│                        AWS Account Foundation                        │
│                                                                      │
│  ┌─────────────────────────────────────────────────────────────┐   │
│  │ VPC (10.0.0.0/16) — Multi-AZ public/private subnets        │   │
│  │                                                             │   │
│  │  Public (10.0.0.0/22)      Private (10.0.16.0/22)          │   │
│  │    AZ-a        AZ-b          AZ-a        AZ-b              │   │
│  │     |           |             |           |                │   │
│  │    IGW ◄────────┴─────────────┴─────────► NAT (optional)   │   │
│  │                                                             │   │
│  │  VPC Endpoints: S3, DynamoDB (free gateway endpoints)      │   │
│  └─────────────────────────────────────────────────────────────┘   │
│                                                                      │
│  ┌─────────────────────────────────────────────────────────────┐   │
│  │ IAM — Three User Groups                                     │   │
│  │  • Admin (full AWS access)                                  │   │
│  │  • Developer (EC2, Lambda, S3, DynamoDB; no IAM)            │   │
│  │  • Read-Only (read access all services)                     │   │
│  │  MFA enforcement on all groups                              │   │
│  │  Strong password policy (14 chars, symbols, 90-day rotate) │   │
│  └─────────────────────────────────────────────────────────────┘   │
│                                                                      │
│  ┌──────────────────────┐  ┌──────────────────────┐                │
│  │ CloudTrail           │  │ Budgets & Alerts     │                │
│  │ • Multi-region trail │  │ • Monthly budget     │                │
│  │ • S3 + CW Logs       │  │ • Safety net limit   │                │
│  │ • API call tracking  │  │ • Per-service limits │                │
│  │ • Log insights       │  │ • 50%, 80%, 100%     │                │
│  │                      │  │                      │                │
│  │ Root account alerts  │  │ SNS Alerts           │                │
│  │ Unauthorized APIs    │  │ • Email              │                │
│  │ IAM policy changes   │  │ • SMS (optional)     │                │
│  │                      │  │ • Slack (optional)   │                │
│  └──────────────────────┘  └──────────────────────┘                │
└─────────────────────────────────────────────────────────────────────┘
```

## What It Provides

| Component | Purpose | Notes |
|-----------|---------|-------|
| **VPC** | Network isolation | 2 AZs, public/private subnets, optional NAT gateway |
| **IAM Groups** | Access control | Admin, Developer, Read-Only with MFA enforcement |
| **CloudTrail** | Audit logging | Multi-region, encrypted S3 storage, CloudWatch Logs |
| **Security Alarms** | Intrusion detection | Root account usage, unauthorized APIs, IAM changes |
| **Budgets** | Cost control | Monthly alerts at 50%, 80%, 100% with SNS notifications |
| **SNS Topics** | Alert routing | Email, SMS, Slack, PagerDuty (configurable) |
| **VPC Endpoints** | Cost savings | S3 and DynamoDB gateway endpoints (free tier) |

## Quick Start

### Prerequisites

- AWS account (new or existing)
- AWS CLI configured with credentials
- Terraform >= 1.5
- Text editor for tfvars

### 1. Clone and configure

```bash
git clone git@github.com:Three-Moons-Network/terraform-aws-starter.git
cd terraform-aws-starter
cp terraform.tfvars.example terraform.tfvars
```

Edit `terraform.tfvars`:

```hcl
project     = "acmecorp"           # Your company name
environment = "prod"
region      = "us-east-1"

# REQUIRED: Email for alert notifications
alert_email_addresses = ["ops@acmecorp.com", "cto@acmecorp.com"]

# Budget — prevents surprise bills
monthly_budget_limit = "500"        # Alert at $500, safety net at $1000
safety_net_limit     = "1000"

# Optional: SMS alerts for critical issues
enable_sms_alerts            = true
critical_alert_phone_numbers = ["+14155552671"]  # E.164 format
```

### 2. Validate

```bash
terraform init -backend=false
terraform fmt -check -recursive
terraform validate
```

### 3. Plan

```bash
terraform plan -out=tfplan
```

Review the output — pay special attention to:
- VPC CIDR conflicts with existing networks
- IAM group names (must be unique in account)
- Budget thresholds

### 4. Apply

```bash
terraform apply tfplan
```

This takes ~5-10 minutes. CloudTrail may need a few minutes more to start collecting logs.

### 5. Post-deployment

AWS will send SNS confirmation emails to the addresses in `alert_email_addresses`. **Click the confirmation link** to subscribe.

Also manually:

1. **Enable MFA on root account** (AWS Console → Account settings → MFA device)
2. **Do NOT create access keys for root account** (follow the [AWS security guidelines](https://docs.aws.amazon.com/IAM/latest/UserGuide/id_root-user.html))
3. **Review CloudTrail logs** (AWS Console → CloudTrail → Event history)
4. **(Optional) Set up Slack integration** (see Customization section)

## Project Structure

```
.
├── main.tf                          # Root composition of modules
├── variables.tf                     # Input variables (region, budget, etc.)
├── outputs.tf                       # Exported resource IDs
├── terraform.tfvars.example         # Example configuration (copy and edit)
├── backend.tf                       # Remote state config (commented)
├── .github/workflows/ci.yml         # GitHub Actions: fmt, validate, tflint
├── modules/
│   ├── vpc/                         # VPC, subnets, endpoints
│   │   ├── main.tf
│   │   ├── variables.tf
│   │   └── outputs.tf
│   ├── iam-baseline/                # IAM groups, password policy, MFA enforcement
│   │   ├── main.tf
│   │   ├── variables.tf
│   │   └── outputs.tf
│   ├── cloudtrail/                  # Audit logging, security alarms
│   │   ├── main.tf
│   │   ├── variables.tf
│   │   └── outputs.tf
│   ├── budgets/                     # Cost alerts, monthly/safety-net budgets
│   │   ├── main.tf
│   │   ├── variables.tf
│   │   └── outputs.tf
│   └── alerting/                    # SNS topics, email/SMS/Slack/PagerDuty
│       ├── main.tf
│       ├── variables.tf
│       └── outputs.tf
├── .gitignore
└── README.md                        # This file
```

## Cost Estimate

For a fresh AWS account with the baseline running:

| Component | Monthly Cost | Notes |
|-----------|--------------|-------|
| VPC | $0 | No charge for VPC itself |
| NAT Gateway (if enabled) | ~$32 | $0.045/hour + data transfer; disable for dev |
| CloudTrail | ~$2-5 | Management events free; data events ~$0.10 per 100k |
| S3 (CloudTrail logs) | ~$0.50 | Lifecycle to Glacier after 90 days |
| CloudWatch Logs (CloudTrail + flow logs) | ~$1-3 | Depends on activity and retention |
| Budgets | $0 | 4 budgets free, $0.01/budget beyond |
| SNS | ~$0 | Email is free; SMS is $0.00645 per message |
| **Total infrastructure** | ~$5-40 | Scales with activity; mostly log costs |

**Most of the cost is CloudTrail and logging.** To reduce:
- Set `enable_flow_logs = false` (saves ~$1)
- Reduce `cloudtrail_log_retention_days` to 7 (saves ~$0.50)
- Disable data event logging in CloudTrail if you don't need it

## Customization

### Change VPC CIDR

Edit `terraform.tfvars`:

```hcl
vpc_cidr = "10.1.0.0/16"  # Use /16 for future growth
```

### Enable NAT Gateway for Private Subnet Egress

If workloads need outbound internet access without public IPs:

```hcl
enable_nat_gateway = true
```

This creates a NAT gateway in the public subnet and routes all private traffic through it. Cost: ~$32/month + data transfer.

### Add IAM Users to Groups

```bash
aws iam add-user-to-group --group-name acmecorp-developer --user-name alice
aws iam add-user-to-group --group-name acmecorp-developer --user-name bob
```

Then require MFA setup:

```bash
aws iam create-virtual-mfa-device --virtual-mfa-device-name "alice-mfa" \
  --outfile /tmp/mfa-alice.txt
# Print and scan QR code with authenticator app
```

### Enable Slack Notifications

Create a Lambda function to format CloudWatch alarms as Slack messages:

```bash
# 1. Create a Slack app at https://api.slack.com/apps
# 2. Create an Incoming Webhook for your channel (get webhook URL)
# 3. Deploy a Lambda that reads SNS, formats, and posts to Slack webhook
# 4. Subscribe Lambda to SNS topic

enable_slack_integration = true
```

Detailed instructions: [Slack + CloudWatch Integration Guide](https://docs.aws.amazon.com/AmazonCloudWatch/latest/events/TakeAction.html)

### Enable PagerDuty Alerting

For on-call critical alerts:

```hcl
enable_pagerduty_integration = true
pagerduty_webhook_url        = "https://events.pagerduty.com/..."  # From PagerDuty integration
```

### Enable Service-Specific Budgets

To track Lambda, DynamoDB, and S3 spending separately:

```hcl
enable_service_budgets = true
lambda_budget_limit    = "100"
dynamodb_budget_limit  = "100"
s3_budget_limit        = "100"
```

### Set Up Remote State

For team environments, use S3 + DynamoDB for state locking:

```bash
# 1. Create state bucket and table (one-time)
aws s3 mb s3://mycompany-tf-state-123456789
aws s3api put-bucket-versioning --bucket mycompany-tf-state-123456789 \
  --versioning-configuration Status=Enabled
aws s3api put-bucket-encryption --bucket mycompany-tf-state-123456789 \
  --server-side-encryption-configuration '{
    "Rules": [{
      "ApplyServerSideEncryptionByDefault": {"SSEAlgorithm": "AES256"}
    }]
  }'

aws dynamodb create-table --table-name terraform-locks \
  --attribute-definitions AttributeName=LockID,AttributeType=S \
  --key-schema AttributeName=LockID,KeyType=HASH \
  --provisioned-throughput ReadCapacityUnits=5,WriteCapacityUnits=5

# 2. Uncomment backend block in backend.tf

# 3. Migrate state
terraform init
```

## Security Notes

### Root Account

This Terraform module does **not** and cannot enforce:
- MFA on root account (manual: AWS Console → Account settings)
- No root access keys (follow AWS guidance)
- Root account login alerts (use CloudWatch metric filters + SNS)

Do these manually after running Terraform.

### IAM Password Policy

Enforced by `iam-baseline` module:
- Minimum 14 characters
- Symbols, numbers, uppercase, lowercase required
- Expires in 90 days
- Cannot reuse last 24 passwords

Users must change password on first login.

### MFA Enforcement

All IAM groups have an inline policy that denies all actions except:
- Listing credentials
- Creating/syncing MFA devices
- Changing password

This forces users to set up MFA before accessing AWS services.

### CloudTrail

Logs all API calls (management events) to S3 and CloudWatch Logs. Optional data events track:
- S3 object access
- Lambda function invocations

### Network Segmentation

- **Public subnets**: Auto-assign public IPs, route to IGW
- **Private subnets**: No public IPs, optional route to NAT
- **Default security group**: No rules (force explicit security groups)
- **VPC Endpoints**: S3 and DynamoDB available without internet

## Tear Down

When you're done (dev/staging testing):

```bash
terraform destroy
```

This removes:
- VPC and subnets
- IAM groups and policies
- CloudTrail and S3 bucket (preserves logs)
- SNS topics
- CloudWatch alarms and log groups
- Budgets

**Note:** S3 bucket retention and log group retention settings may prevent immediate deletion. Delete those manually if needed.

## Outputs

After `terraform apply`, Terraform outputs:

```
vpc_id                         = "vpc-0123456789abcdef0"
public_subnet_ids              = ["subnet-...", "subnet-..."]
private_subnet_ids             = ["subnet-...", "subnet-..."]
availability_zones             = ["us-east-1a", "us-east-1b"]

admin_group_name               = "acmecorp-admin"
developer_group_name           = "acmecorp-developer"
read_only_group_name           = "acmecorp-read-only"

cloudtrail_s3_bucket_name      = "acmecorp-cloudtrail-logs-..."
cloudtrail_cloudwatch_log_group = "/aws/cloudtrail/acmecorp"

ops_alerts_topic_arn           = "arn:aws:sns:us-east-1:...:acmecorp-ops-alerts"
critical_alerts_topic_arn      = "arn:aws:sns:us-east-1:...:acmecorp-critical-alerts"

main_budget_name               = "acmecorp-monthly-budget"
```

## CI/CD

GitHub Actions runs on every push/PR:

- **Format check** — `terraform fmt -check`
- **Validation** — `terraform validate` (no AWS credentials needed)
- **TFLint** — Linting for best practices (S3 bucket encryption, resource naming, etc.)
- **Terraform Docs** — Auto-generates module documentation (optional)

## Known Limitations

1. **Cannot enforce root account settings**: MFA and access keys on root are manual
2. **IAM cannot manage CloudTrail lifecycle**: S3 lifecycle rules are managed by the module, but manual intervention may be needed for compliance
3. **VPC Flow Logs are optional and disabled by default** because they add cost (~$1/month for moderate traffic)
4. **No automatic remediation**: CloudWatch alarms alert but don't auto-remediate (e.g., disable compromised keys)

## Next Steps

After deploying this foundation:

1. **Add an application VPC** (separate stack for workloads)
2. **Deploy Lambda/containers** in private subnets
3. **Add RDS/DynamoDB** in private subnets
4. **Set up backups** (EBS snapshots, RDS backups, DynamoDB backups)
5. **Add observability** (CloudWatch dashboards, custom metrics, distributed tracing)
6. **Implement disaster recovery** (multi-region failover, backup strategies)

## License

MIT

## Author

Charles Harvey ([linuxlsr](https://github.com/linuxlsr)) — [Three Moons Network LLC](https://threemoonsnetwork.net)

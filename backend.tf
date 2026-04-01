# Remote state backend — uncomment and configure for your environment
# For local development, comment this out and use local state (default)

# terraform {
#   backend "s3" {
#     bucket         = "your-terraform-state-bucket"
#     key            = "terraform-aws-starter/terraform.tfstate"
#     region         = "us-east-1"
#     encrypt        = true
#     dynamodb_table = "terraform-locks"
#   }
# }

# Note: Before using remote state:
# 1. Create S3 bucket: aws s3 mb s3://your-terraform-state-bucket
# 2. Enable versioning: aws s3api put-bucket-versioning --bucket your-terraform-state-bucket --versioning-configuration Status=Enabled
# 3. Enable encryption: aws s3api put-bucket-encryption --bucket your-terraform-state-bucket --server-side-encryption-configuration '{"Rules":[{"ApplyServerSideEncryptionByDefault":{"SSEAlgorithm":"AES256"}}]}'
# 4. Block public access: aws s3api put-public-access-block --bucket your-terraform-state-bucket --public-access-block-configuration "BlockPublicAcls=true,IgnorePublicAcls=true,BlockPublicPolicy=true,RestrictPublicBuckets=true"
# 5. Create DynamoDB table: aws dynamodb create-table --table-name terraform-locks --attribute-definitions AttributeName=LockID,AttributeType=S --key-schema AttributeName=LockID,KeyType=HASH --provisioned-throughput ReadCapacityUnits=5,WriteCapacityUnits=5
# 6. Uncomment the backend block above
# 7. Run: terraform init

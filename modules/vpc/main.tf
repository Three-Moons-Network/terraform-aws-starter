###############################################################################
# VPC Module — Foundation for AWS account
#
# Configurable CIDR, public and private subnets across 2 AZs with optional
# NAT gateway and flow logs. VPC endpoints for S3 and DynamoDB built-in.
###############################################################################

data "aws_availability_zones" "available" {
  state = "available"

  filter {
    name   = "opt-in-status"
    values = ["opt-in-not-required"]
  }
}

locals {
  azs = slice(data.aws_availability_zones.available.names, 0, 2)

  # /22 subnets within the VPC CIDR
  # Public:  x.x.0.0/22, x.x.4.0/22
  # Private: x.x.16.0/22, x.x.20.0/22
  public_cidrs  = [for i in range(2) : cidrsubnet(var.vpc_cidr, 2, i)]
  private_cidrs = [for i in range(2) : cidrsubnet(var.vpc_cidr, 2, i + 4)]

  common_tags = {
    Project   = var.project
    Environment = var.environment
    ManagedBy   = "Terraform"
  }
}

data "aws_region" "current" {}

# ---------------------------------------------------------------------------
# VPC
# ---------------------------------------------------------------------------

resource "aws_vpc" "this" {
  cidr_block           = var.vpc_cidr
  enable_dns_support   = true
  enable_dns_hostnames = true

  tags = merge(
    local.common_tags,
    {
      Name = "${var.project}-vpc-${var.environment}"
    }
  )
}

# ---------------------------------------------------------------------------
# Internet Gateway
# ---------------------------------------------------------------------------

resource "aws_internet_gateway" "this" {
  vpc_id = aws_vpc.this.id

  tags = merge(
    local.common_tags,
    {
      Name = "${var.project}-igw-${var.environment}"
    }
  )
}

# ---------------------------------------------------------------------------
# Public Subnets
# ---------------------------------------------------------------------------

resource "aws_subnet" "public" {
  count = 2

  vpc_id                  = aws_vpc.this.id
  cidr_block              = local.public_cidrs[count.index]
  availability_zone       = local.azs[count.index]
  map_public_ip_on_launch = true

  tags = merge(
    local.common_tags,
    {
      Name = "${var.project}-public-${var.environment}-${local.azs[count.index]}"
      Tier = "public"
    }
  )
}

resource "aws_route_table" "public" {
  vpc_id = aws_vpc.this.id

  tags = merge(
    local.common_tags,
    {
      Name = "${var.project}-rt-public-${var.environment}"
    }
  )
}

resource "aws_route" "public_internet" {
  route_table_id         = aws_route_table.public.id
  destination_cidr_block = "0.0.0.0/0"
  gateway_id             = aws_internet_gateway.this.id
}

resource "aws_route_table_association" "public" {
  count = 2

  subnet_id      = aws_subnet.public[count.index].id
  route_table_id = aws_route_table.public.id
}

# ---------------------------------------------------------------------------
# Private Subnets
# ---------------------------------------------------------------------------

resource "aws_subnet" "private" {
  count = 2

  vpc_id            = aws_vpc.this.id
  cidr_block        = local.private_cidrs[count.index]
  availability_zone = local.azs[count.index]

  tags = merge(
    local.common_tags,
    {
      Name = "${var.project}-private-${var.environment}-${local.azs[count.index]}"
      Tier = "private"
    }
  )
}

resource "aws_route_table" "private" {
  vpc_id = aws_vpc.this.id

  tags = merge(
    local.common_tags,
    {
      Name = "${var.project}-rt-private-${var.environment}"
    }
  )
}

resource "aws_route_table_association" "private" {
  count = 2

  subnet_id      = aws_subnet.private[count.index].id
  route_table_id = aws_route_table.private.id
}

# ---------------------------------------------------------------------------
# NAT Gateway (optional, defaults off for cost)
# ---------------------------------------------------------------------------

resource "aws_eip" "nat" {
  count  = var.enable_nat_gateway ? 1 : 0
  domain = "vpc"

  depends_on = [aws_internet_gateway.this]

  tags = merge(
    local.common_tags,
    {
      Name = "${var.project}-eip-nat-${var.environment}"
    }
  )
}

resource "aws_nat_gateway" "this" {
  count         = var.enable_nat_gateway ? 1 : 0
  subnet_id     = aws_subnet.public[0].id
  allocation_id = aws_eip.nat[0].id

  tags = merge(
    local.common_tags,
    {
      Name = "${var.project}-nat-${var.environment}"
    }
  )

  depends_on = [aws_internet_gateway.this]
}

resource "aws_route" "private_nat" {
  count              = var.enable_nat_gateway ? 1 : 0
  route_table_id     = aws_route_table.private.id
  destination_cidr_block = "0.0.0.0/0"
  nat_gateway_id     = aws_nat_gateway.this[0].id
}

# ---------------------------------------------------------------------------
# VPC Endpoints — free gateway endpoints for S3 and DynamoDB
# ---------------------------------------------------------------------------

resource "aws_vpc_endpoint" "s3" {
  vpc_id       = aws_vpc.this.id
  service_name = "com.amazonaws.${data.aws_region.current.name}.s3"

  route_table_ids = [
    aws_route_table.public.id,
    aws_route_table.private.id,
  ]

  tags = merge(
    local.common_tags,
    {
      Name = "${var.project}-vpce-s3-${var.environment}"
    }
  )
}

resource "aws_vpc_endpoint" "dynamodb" {
  vpc_id       = aws_vpc.this.id
  service_name = "com.amazonaws.${data.aws_region.current.name}.dynamodb"

  route_table_ids = [
    aws_route_table.public.id,
    aws_route_table.private.id,
  ]

  tags = merge(
    local.common_tags,
    {
      Name = "${var.project}-vpce-dynamodb-${var.environment}"
    }
  )
}

# ---------------------------------------------------------------------------
# Flow Logs (optional, defaults off)
# ---------------------------------------------------------------------------

resource "aws_cloudwatch_log_group" "flow_logs" {
  count = var.enable_flow_logs ? 1 : 0

  name              = "/aws/vpc/${var.project}-${var.environment}"
  retention_in_days = var.flow_logs_retention_days

  tags = merge(
    local.common_tags,
    {
      Name = "${var.project}-flow-logs-${var.environment}"
    }
  )
}

resource "aws_iam_role" "flow_logs" {
  count = var.enable_flow_logs ? 1 : 0
  name  = "${var.project}-vpc-flow-logs-${var.environment}"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Action = "sts:AssumeRole"
      Effect = "Allow"
      Principal = {
        Service = "vpc-flow-logs.amazonaws.com"
      }
    }]
  })

  tags = local.common_tags
}

resource "aws_iam_role_policy" "flow_logs" {
  count = var.enable_flow_logs ? 1 : 0
  name  = "${var.project}-vpc-flow-logs-${var.environment}"
  role  = aws_iam_role.flow_logs[0].id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Action = [
        "logs:CreateLogGroup",
        "logs:CreateLogStream",
        "logs:PutLogEvents",
        "logs:DescribeLogGroups",
        "logs:DescribeLogStreams",
      ]
      Effect   = "Allow"
      Resource = "*"
    }]
  })
}

resource "aws_flow_log" "this" {
  count = var.enable_flow_logs ? 1 : 0

  vpc_id                   = aws_vpc.this.id
  traffic_type             = "ALL"
  log_destination_type     = "cloud-watch-logs"
  log_destination          = aws_cloudwatch_log_group.flow_logs[0].arn
  iam_role_arn             = aws_iam_role.flow_logs[0].arn
  log_format               = "${var.project}-vpc-flow-logs"
  max_aggregation_interval = 60

  tags = merge(
    local.common_tags,
    {
      Name = "${var.project}-flow-logs-${var.environment}"
    }
  )
}

# ---------------------------------------------------------------------------
# Default Security Group — explicitly locked down
# ---------------------------------------------------------------------------

resource "aws_default_security_group" "this" {
  vpc_id = aws_vpc.this.id

  tags = merge(
    local.common_tags,
    {
      Name = "${var.project}-default-sg-${var.environment}-DO-NOT-USE"
    }
  )

  # No ingress/egress rules — force explicit security groups
}

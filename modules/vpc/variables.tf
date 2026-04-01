variable "vpc_cidr" {
  description = "CIDR block for the VPC (e.g., 10.0.0.0/16)"
  type        = string
}

variable "environment" {
  description = "Environment name (dev, staging, prod)"
  type        = string
}

variable "project" {
  description = "Project name for tagging and naming"
  type        = string
}

variable "enable_nat_gateway" {
  description = "Enable NAT gateway for private subnet egress (default: false for cost)"
  type        = bool
  default     = false
}

variable "enable_flow_logs" {
  description = "Enable VPC flow logs to CloudWatch"
  type        = bool
  default     = false
}

variable "flow_logs_retention_days" {
  description = "CloudWatch log retention for flow logs in days"
  type        = number
  default     = 7
}

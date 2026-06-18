variable "aws_region" {
  description = "AWS region to deploy into (diagram specifies eu-west-2 / London for UK data residency)"
  type        = string
  default     = "eu-west-2"
}

variable "project_name" {
  description = "Short name used to prefix resource names and tags"
  type        = string
  default     = "payroll"
}

variable "availability_zones" {
  description = "AZs to spread the VPC subnets across. Index 0 = AZ-1, index 1 = AZ-2 in the diagram"
  type        = list(string)
  default     = ["eu-west-2a", "eu-west-2b"]
}

variable "vpc_cidr" {
  description = "CIDR block for the VPC"
  type        = string
  default     = "10.0.0.0/16"
}

variable "public_subnet_cidrs" {
  description = "CIDR blocks for the public subnets, one per AZ"
  type        = list(string)
  default     = ["10.0.1.0/24", "10.0.2.0/24"]
}

variable "private_subnet_cidrs" {
  description = "CIDR blocks for the private subnets, one per AZ"
  type        = list(string)
  default     = ["10.0.11.0/24", "10.0.12.0/24"]
}

# Drives every per-tenant resource (SG, IAM role, EC2, target group, S3 prefix, alarms)
variable "tenants" {
  description = "Map of tenant key -> S3 prefix used for IAM scoping and tagging"
  type        = map(string)
  default = {
    companies = "company"
    bureaus   = "bureau"
    employees = "employee"
  }
}

# Diagram has tenants in AZ-2 (index 1); AZ-1 is reserved for future expansion
variable "tenant_subnet_az_index" {
  description = "Index into availability_zones / private_subnet_cidrs where tenant EC2 instances are placed"
  type        = number
  default     = 1
}

variable "instance_type" {
  description = "EC2 instance type for tenant portals"
  type        = string
  default     = "t3.micro"
}

variable "db_instance_class" {
  description = "RDS instance class"
  type        = string
  default     = "db.t3.micro"
}

variable "db_allocated_storage" {
  description = "RDS allocated storage in GB"
  type        = number
  default     = 20
}

variable "db_name" {
  description = "Initial database name"
  type        = string
  default     = "payrolldb"
}

variable "db_username" {
  description = "Master username for the RDS instance"
  type        = string
  default     = "admin"
  sensitive   = true
}

variable "github_repository" {
  description = "GitHub \"owner/repo\" allowed to assume the CI/CD deploy role via OIDC"
  type        = string
  default     = "HenalMehta09/Ocean-Across-DevOps-Assignment"
}

variable "alert_email" {
  description = "Email address subscribed to the SNS critical-alerts topic"
  type        = string
}

# The HTTPS listener itself always exists (self-signed cert, see tls.tf) so
# transit encryption isn't gated behind owning a domain. This flag only turns
# on the things that genuinely require a real, owned domain: Route 53 records,
# host-based tenant routing, and swapping in a real CA-signed cert.
variable "enable_dns_and_tls" {
  description = "If true, creates Route 53 records, host-based tenant routing, and uses acm_certificate_arn (a real cert) instead of the default self-signed one. Requires domain_name and acm_certificate_arn"
  type        = bool
  default     = false
}

variable "domain_name" {
  description = "Existing Route 53 hosted zone domain name (only used when enable_dns_and_tls = true)"
  type        = string
  default     = ""
}

variable "acm_certificate_arn" {
  description = "Real, CA-signed ACM certificate ARN for the ALB HTTPS listener (only used when enable_dns_and_tls = true; otherwise a self-signed cert is used instead)"
  type        = string
  default     = ""
}

variable "enable_waf" {
  description = "Attach an AWS WAFv2 Web ACL to the ALB (shown as 'Optional' in the diagram)"
  type        = bool
  default     = true
}

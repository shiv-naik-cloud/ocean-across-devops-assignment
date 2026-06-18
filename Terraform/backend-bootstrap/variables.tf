variable "aws_region" {
  description = "AWS region for the state bucket and lock table"
  type        = string
  default     = "eu-west-2"
}

variable "project_name" {
  description = "Short name used to prefix bootstrap resource names"
  type        = string
  default     = "payroll"
}

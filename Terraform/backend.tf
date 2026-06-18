# bucket/dynamodb_table/region come from backend-bootstrap/ output, supplied
# at init time via -backend-config (see backend.hcl.example)

terraform {
  required_version = ">= 1.5.0"

  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
    random = {
      source  = "hashicorp/random"
      version = "~> 3.0"
    }
    tls = {
      source  = "hashicorp/tls"
      version = "~> 4.0"
    }
  }

  backend "s3" {
    key     = "payroll-platform/terraform.tfstate"
    encrypt = true
  }
}

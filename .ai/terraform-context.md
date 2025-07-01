# 🏗️ Terraform/OpenTofu Context for ValkyrieVault

## Current Infrastructure State

### Provider Versions

```hcl
terraform {
  required_version = ">= 1.6.0"
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
    random = {
      source  = "hashicorp/random"
      version = "~> 3.4"
    }
  }
}
```

### Existing Modules Structure

```
terraform/modules/
├── s3-backup/          # S3 backup storage with lifecycle
├── iam/               # IAM users and policies
├── monitoring/        # CloudWatch integration
└── networking/        # VPC and security groups (if used)
```

### Environment Configuration Pattern

```hcl
# Standard variable structure for all environments
variable "aws_region" {
  description = "AWS region for resources"
  type        = string
  default     = "eu-west-3"
}

variable "environment" {
  description = "Environment name"
  type        = string
  validation {
    condition     = contains(["dev", "staging", "prod"], var.environment)
    error_message = "Environment must be dev, staging, or prod."
  }
}

variable "backup_retention_days" {
  description = "Backup retention configuration"
  type = object({
    hourly  = number
    daily   = number
    monthly = number
    yearly  = number
  })
}
```

### Standard Resource Naming

```
{project_name}-{environment}-{service}-{purpose}-{random_suffix}
Example: vaultwarden-prod-backups-primary-a1b2c3d4
```

### Required Tags

```hcl
locals {
  common_tags = {
    Project     = var.project_name
    Environment = var.environment
    ManagedBy   = "opentofu"
    CreatedAt   = timestamp()
    Purpose     = "backup-storage"  # Specific to resource
  }
}
```

### Current S3 Backup Module Interface

```hcl
module "backup_storage" {
  source = "../../modules/s3-backup"

  project_name = var.project_name
  environment  = var.environment

  backup_retention_days = {
    hourly  = 2
    daily   = 30
    monthly = 12
    yearly  = 5
  }

  enable_cross_region_replication = var.environment == "prod"
  enable_mfa_delete = var.environment == "prod"
}
```

### Security Standards

- All S3 buckets must have encryption enabled
- Versioning enabled on critical buckets
- MFA delete enabled for production
- Bucket policies enforce HTTPS only
- All resources use least privilege IAM policies

### Multi-Environment Patterns

- Separate AWS accounts per environment (optional)
- Environment-specific retention policies
- Production gets enhanced backup features
- Development gets reduced costs configuration

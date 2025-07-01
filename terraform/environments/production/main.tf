# terraform/environments/prod/main.tf
terraform {
  required_version = ">= 1.0"
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

provider "aws" {
  region = var.aws_region
  
  default_tags {
    tags = {
      Project     = "vaultwarden"
      Environment = var.environment
      ManagedBy   = "opentofu"
    }
  }
}

# Variables
variable "aws_region" {
  description = "AWS region"
  type        = string
  default     = "eu-west-3" # Paris
}

variable "environment" {
  description = "Environment name"
  type        = string
  default     = "prod"
}

variable "project_name" {
  description = "Project name"
  type        = string
  default     = "vaultwarden"
}

# Génération de clés de chiffrement
resource "random_password" "backup_encryption_key" {
  length  = 32
  special = true
}

resource "random_password" "admin_token" {
  length  = 64
  special = false
}

# Module S3 pour les sauvegardes
module "backup_storage" {
  source = "../../modules/s3-backup"
  
  project_name = var.project_name
  environment  = var.environment
  
  backup_retention_days = {
    hourly  = 2   # 48 sauvegardes horaires
    daily   = 30  # 30 sauvegardes quotidiennes
    monthly = 12  # 12 sauvegardes mensuelles
    yearly  = 5   # 5 sauvegardes annuelles
  }
}

# Module IAM
module "iam" {
  source = "../../modules/iam"
  
  project_name = var.project_name
  environment  = var.environment
  s3_bucket_arn = module.backup_storage.bucket_arn
}

# Secrets Manager pour stocker les variables sensibles
resource "aws_secretsmanager_secret" "vaultwarden_config" {
  name = "${var.project_name}-${var.environment}-config"
  description = "Vaultwarden configuration secrets"
  
  recovery_window_in_days = 7
}

resource "aws_secretsmanager_secret_version" "vaultwarden_config" {
  secret_id = aws_secretsmanager_secret.vaultwarden_config.id
  secret_string = jsonencode({
    admin_token           = random_password.admin_token.result
    backup_encryption_key = random_password.backup_encryption_key.result
    s3_access_key        = module.iam.access_key_id
    s3_secret_key        = module.iam.secret_access_key
    s3_bucket           = module.backup_storage.bucket_name
    s3_region           = var.aws_region
  })
}

# Outputs
output "s3_bucket_name" {
  value = module.backup_storage.bucket_name
}

output "iam_access_key_id" {
  value = module.iam.access_key_id
}

output "secrets_manager_arn" {
  value = aws_secretsmanager_secret.vaultwarden_config.arn
}

# terraform/modules/s3-backup/main.tf
variable "project_name" {
  description = "Project name"
  type        = string
}

variable "environment" {
  description = "Environment"
  type        = string
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

# Bucket principal pour les sauvegardes
resource "aws_s3_bucket" "backup" {
  bucket = "${var.project_name}-${var.environment}-backups-${random_id.bucket_suffix.hex}"
}

resource "random_id" "bucket_suffix" {
  byte_length = 4
}

# Versioning
resource "aws_s3_bucket_versioning" "backup" {
  bucket = aws_s3_bucket.backup.id
  versioning_configuration {
    status = "Enabled"
  }
}

# Chiffrement
resource "aws_s3_bucket_server_side_encryption_configuration" "backup" {
  bucket = aws_s3_bucket.backup.id

  rule {
    apply_server_side_encryption_by_default {
      sse_algorithm = "AES256"
    }
    bucket_key_enabled = true
  }
}

# Lifecycle pour la gestion des sauvegardes
resource "aws_s3_bucket_lifecycle_configuration" "backup" {
  bucket = aws_s3_bucket.backup.id

  rule {
    id     = "hourly_backups"
    status = "Enabled"
    
    filter {
      prefix = "hourly/"
    }

    expiration {
      days = var.backup_retention_days.hourly
    }
  }

  rule {
    id     = "daily_backups"
    status = "Enabled"
    
    filter {
      prefix = "daily/"
    }

    expiration {
      days = var.backup_retention_days.daily
    }

    transition {
      days          = 7
      storage_class = "STANDARD_IA"
    }

    transition {
      days          = 30
      storage_class = "GLACIER"
    }
  }

  rule {
    id     = "monthly_backups"
    status = "Enabled"
    
    filter {
      prefix = "monthly/"
    }

    expiration {
      days = var.backup_retention_days.monthly * 30
    }

    transition {
      days          = 1
      storage_class = "GLACIER"
    }

    transition {
      days          = 90
      storage_class = "DEEP_ARCHIVE"
    }
  }
}

# Politique de bucket
resource "aws_s3_bucket_policy" "backup" {
  bucket = aws_s3_bucket.backup.id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Sid       = "DenyUnSecureCommunications"
        Effect    = "Deny"
        Principal = "*"
        Action    = "s3:*"
        Resource = [
          aws_s3_bucket.backup.arn,
          "${aws_s3_bucket.backup.arn}/*"
        ]
        Condition = {
          Bool = {
            "aws:SecureTransport" = "false"
          }
        }
      }
    ]
  })
}

# Outputs
output "bucket_name" {
  value = aws_s3_bucket.backup.bucket
}

output "bucket_arn" {
  value = aws_s3_bucket.backup.arn
}

output "bucket_domain_name" {
  value = aws_s3_bucket.backup.bucket_domain_name
}

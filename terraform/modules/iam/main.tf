# terraform/modules/iam/main.tf
variable "project_name" {
  description = "Project name"
  type        = string
}

variable "environment" {
  description = "Environment"
  type        = string
}

variable "s3_bucket_arn" {
  description = "S3 bucket ARN for backups"
  type        = string
}

# Utilisateur pour les sauvegardes
resource "aws_iam_user" "backup_user" {
  name = "${var.project_name}-${var.environment}-backup-user"
  path = "/system/"
}

# Clés d'accès
resource "aws_iam_access_key" "backup_user" {
  user = aws_iam_user.backup_user.name
}

# Politique pour l'accès S3
resource "aws_iam_policy" "backup_policy" {
  name        = "${var.project_name}-${var.environment}-backup-policy"
  description = "Policy for Vaultwarden backup operations"

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Action = [
          "s3:ListBucket",
          "s3:GetBucketLocation"
        ]
        Resource = var.s3_bucket_arn
      },
      {
        Effect = "Allow"
        Action = [
          "s3:GetObject",
          "s3:PutObject",
          "s3:DeleteObject"
        ]
        Resource = "${var.s3_bucket_arn}/*"
      }
    ]
  })
}

# Attachement de la politique
resource "aws_iam_user_policy_attachment" "backup_user_policy" {
  user       = aws_iam_user.backup_user.name
  policy_arn = aws_iam_policy.backup_policy.arn
}

# Outputs
output "access_key_id" {
  value = aws_iam_access_key.backup_user.id
}

output "secret_access_key" {
  value     = aws_iam_access_key.backup_user.secret
  sensitive = true
}

output "user_arn" {
  value = aws_iam_user.backup_user.arn
}

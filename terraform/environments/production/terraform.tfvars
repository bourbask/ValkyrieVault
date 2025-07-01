# terraform/environments/production/terraform.tfvars
aws_region = "eu-west-3"
environment = "production"
project_name = "vaultwarden"

# Configuration complète
backup_retention_days = {
  hourly  = 2    # 48 sauvegardes horaires
  daily   = 30   # 30 sauvegardes quotidiennes
  monthly = 12   # 12 sauvegardes mensuelles
  yearly  = 5    # 5 sauvegardes annuelles
}

enable_monitoring = true
enable_multi_region_backup = true
instance_type = "t3.medium"

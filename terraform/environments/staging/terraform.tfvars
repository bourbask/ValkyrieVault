# terraform/environments/staging/terraform.tfvars
aws_region = "eu-west-3"
environment = "staging"
project_name = "vaultwarden"

# Configuration proche de la prod mais réduite
backup_retention_days = {
  hourly  = 1    # 24 sauvegardes horaires
  daily   = 14   # 14 sauvegardes quotidiennes
  monthly = 6    # 6 sauvegardes mensuelles
  yearly  = 2    # 2 sauvegardes annuelles
}

enable_monitoring = true
instance_type = "t3.small"

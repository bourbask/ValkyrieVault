# terraform/environments/development/terraform.tfvars
aws_region = "eu-west-3"
environment = "dev"
project_name = "vaultwarden"

# Configuration allégée pour dev
backup_retention_days = {
  hourly  = 1    # 24 sauvegardes horaires
  daily   = 7    # 7 sauvegardes quotidiennes
  monthly = 3    # 3 sauvegardes mensuelles
  yearly  = 1    # 1 sauvegarde annuelle
}

# Instance plus petite, monitoring réduit
enable_monitoring = false
instance_type = "t3.micro"

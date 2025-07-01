# terraform/environments/prod/backend.tf
terraform {
  backend "s3" {
    bucket = "ton-nom-terraform-state"
    key    = "vaultwarden/prod/terraform.tfstate"
    region = "eu-west-3"
    
    # Optionnel: DynamoDB pour le verrouillage d'état
    dynamodb_table = "terraform-state-lock"
    encrypt        = true
  }
}

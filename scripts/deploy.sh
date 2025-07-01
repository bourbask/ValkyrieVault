#!/bin/bash
# scripts/deploy.sh

set -euo pipefail

echo "🚀 Déploiement de l'infrastructure Vaultwarden"

# 1. Déploiement de l'infrastructure AWS
echo "📦 Déploiement infrastructure AWS..."
cd terraform/environments/prod
tofu init
tofu plan -out=tfplan
tofu apply tfplan

# 2. Récupération des outputs
BUCKET_NAME=$(tofu output -raw s3_bucket_name)
AWS_ACCESS_KEY=$(tofu output -raw iam_access_key_id)

echo "✅ Infrastructure déployée"
echo "📦 Bucket S3: $BUCKET_NAME"

# 3. Configuration du VPS
echo "🖥️ Configuration du VPS..."
cd ../../../ansible
ansible-playbook -i inventory/prod playbooks/setup-vps.yml

echo "✅ Déploiement terminé !"

#!/bin/bash
# scripts/backup-daily.sh

set -euo pipefail

readonly TIMESTAMP=$(date +"%Y%m%d-%H%M%S")
readonly BACKUP_NAME="vw-daily-${TIMESTAMP}"

# Sauvegarde complète (base + attachments + config)
tar -czf "/tmp/${BACKUP_NAME}.tar.gz" -C /source .

# Chiffrement
gpg --symmetric --cipher-algo AES256 --compress-algo 1 --s2k-mode 3 \
    --s2k-digest-algo SHA512 --s2k-count 65536 --force-mdc \
    --passphrase "${BACKUP_ENCRYPTION_KEY}" \
    --output "/tmp/${BACKUP_NAME}.tar.gz.gpg" "/tmp/${BACKUP_NAME}.tar.gz"

# Upload vers multiple destinations
aws s3 cp "/tmp/${BACKUP_NAME}.tar.gz.gpg" \
    "s3://${S3_BUCKET}/daily/${BACKUP_NAME}.tar.gz.gpg" \
    --endpoint-url "${S3_ENDPOINT}"

# Upload vers stockage secondaire (Backblaze, etc.)
if [[ -n "${SECONDARY_S3_ENDPOINT:-}" ]]; then
    aws s3 cp "/tmp/${BACKUP_NAME}.tar.gz.gpg" \
        "s3://${SECONDARY_S3_BUCKET}/daily/${BACKUP_NAME}.tar.gz.gpg" \
        --endpoint-url "${SECONDARY_S3_ENDPOINT}"
fi

# Nettoyage
rm -f "/tmp/${BACKUP_NAME}.*"

# Rotation des sauvegardes (30 quotidiennes, 12 mensuelles)
./cleanup-daily-backups.sh

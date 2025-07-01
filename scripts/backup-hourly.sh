#!/bin/bash
# scripts/backup-hourly.sh

set -euo pipefail

readonly TIMESTAMP=$(date +"%Y%m%d-%H%M%S")
readonly BACKUP_NAME="vw-hourly-${TIMESTAMP}"
readonly MAX_HOURLY_BACKUPS=48

# Sauvegarde de la base SQLite avec verrou
sqlite3 /source/db.sqlite3 ".backup /tmp/${BACKUP_NAME}.sqlite3"

# Compression et chiffrement
tar -czf "/tmp/${BACKUP_NAME}.tar.gz" -C /tmp "${BACKUP_NAME}.sqlite3"
gpg --symmetric --cipher-algo AES256 --compress-algo 1 --s2k-mode 3 \
    --s2k-digest-algo SHA512 --s2k-count 65536 --force-mdc \
    --passphrase "${BACKUP_ENCRYPTION_KEY}" \
    --output "/tmp/${BACKUP_NAME}.tar.gz.gpg" "/tmp/${BACKUP_NAME}.tar.gz"

# Upload vers S3
aws s3 cp "/tmp/${BACKUP_NAME}.tar.gz.gpg" \
    "s3://${S3_BUCKET}/hourly/${BACKUP_NAME}.tar.gz.gpg" \
    --endpoint-url "${S3_ENDPOINT}"

# Nettoyage local
rm -f "/tmp/${BACKUP_NAME}.*"

# Nettoyage des anciennes sauvegardes horaires
aws s3 ls "s3://${S3_BUCKET}/hourly/" --endpoint-url "${S3_ENDPOINT}" \
    | sort -r | tail -n +$((MAX_HOURLY_BACKUPS + 1)) \
    | awk '{print $4}' \
    | xargs -I {} aws s3 rm "s3://${S3_BUCKET}/hourly/{}" --endpoint-url "${S3_ENDPOINT}"

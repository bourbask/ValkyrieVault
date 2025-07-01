#!/bin/bash
# scripts/monitor-backups.sh

# Vérification que les sauvegardes sont récentes
LATEST_HOURLY=$(aws s3 ls "s3://${S3_BUCKET}/hourly/" --endpoint-url "${S3_ENDPOINT}" | tail -1 | awk '{print $1" "$2}')
LATEST_TIMESTAMP=$(date -d "${LATEST_HOURLY}" +%s)
CURRENT_TIMESTAMP=$(date +%s)
DIFF=$((CURRENT_TIMESTAMP - LATEST_TIMESTAMP))

if [[ $DIFF -gt 7200 ]]; then  # Plus de 2h
    # Envoyer alerte (email, webhook, etc.)
    echo "ALERT: Dernière sauvegarde trop ancienne (${DIFF}s)"
fi

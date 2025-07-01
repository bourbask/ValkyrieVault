#!/bin/bash
# scripts/automated-diagnostics.sh

echo "🔍 Vaultwarden Infrastructure Diagnostics"
echo "Timestamp: $(date)"
echo "=========================================="

# System health
echo "📊 System Health:"
uptime
free -h
df -h /

# Container status
echo "🐳 Container Status:"
docker ps -a | grep -E "(vaultwarden|nginx|backup)"

# Service health
echo "🏥 Service Health:"
curl -f --max-time 10 https://vault.yourdomain.com/alive && echo "✅ External access OK" || echo "❌ External access FAILED"
docker exec vaultwarden curl -f --max-time 5 http://localhost:80/alive && echo "✅ Internal health OK" || echo "❌ Internal health FAILED"

# Recent errors
echo "🚨 Recent Errors:"
docker logs vaultwarden --since 1h | grep -i error | tail -5

# Backup status
echo "💾 Backup Status:"
aws s3 ls s3://vaultwarden-prod-backups/hourly/ | tail -3

echo "=========================================="
echo "Diagnostics completed: $(date)"

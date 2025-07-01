# 🔧 Operations Guide

This guide covers day-to-day operations, monitoring, maintenance, and incident response for your ValkyrieVault.

## 📊 Monitoring & Observability

### Health Check Endpoints

| Endpoint   | Purpose               | Expected Response          |
| ---------- | --------------------- | -------------------------- |
| `/alive`   | Basic availability    | `200 OK`                   |
| `/health`  | Detailed health check | JSON with component status |
| `/metrics` | Prometheus metrics    | Prometheus format metrics  |

### Key Metrics to Monitor

#### Application Metrics

```bash
# User activity
vw_users_total
vw_logins_total
vw_vault_items_total

# Performance
vw_request_duration_seconds
vw_request_errors_total
vw_database_connections

# Security
vw_failed_login_attempts
vw_password_breach_checks
```

#### Infrastructure Metrics

```bash
# System resources
node_cpu_usage_percent
node_memory_usage_percent
node_disk_usage_percent
node_network_io_bytes

# Docker containers
container_cpu_usage_percent
container_memory_usage_bytes
container_restart_count
```

#### Backup Metrics

```bash
# Backup operations
backup_success_total
backup_duration_seconds
backup_size_bytes
backup_age_seconds
```

## 🚨 Alerting Strategy

### Critical Alerts (Immediate Response)

```yaml
# Application down
- alert: VaultwardenDown
  expr: up{job="vaultwarden"} == 0
  for: 1m
  severity: critical

# Database corruption
- alert: DatabaseError
  expr: increase(vw_database_errors_total[5m]) > 0
  severity: critical

# Backup failure
- alert: BackupFailed
  expr: time() - backup_last_success_time > 7200 # 2 hours
  severity: critical
```

### Warning Alerts (Next Business Day)

```yaml
# High error rate
- alert: HighErrorRate
  expr: rate(vw_request_errors_total[5m]) > 0.1
  for: 5m
  severity: warning

# Disk space
- alert: DiskSpaceHigh
  expr: node_disk_usage_percent > 80
  for: 10m
  severity: warning
```

## 🔄 Backup Operations

### Backup Verification

```bash
#!/bin/bash
# scripts/verify-backup.sh

set -euo pipefail

ENV=${1:-production}
DATE=${2:-$(date +%Y%m%d)}

echo "🔍 Verifying backups for ${ENV} on ${DATE}"

# Check S3 backup existence
aws s3 ls "s3://vaultwarden-${ENV}-backups/daily/" | grep "${DATE}"

# Download and verify latest backup
LATEST_BACKUP=$(aws s3 ls "s3://vaultwarden-${ENV}-backups/daily/" | sort | tail -n 1 | awk '{print $4}')

if [[ -n "$LATEST_BACKUP" ]]; then
    echo "✅ Latest backup found: $LATEST_BACKUP"

    # Download and test extraction
    aws s3 cp "s3://vaultwarden-${ENV}-backups/daily/$LATEST_BACKUP" "/tmp/$LATEST_BACKUP"

    # Decrypt and verify
    gpg --decrypt --batch --passphrase "${BACKUP_ENCRYPTION_KEY}" \
        "/tmp/$LATEST_BACKUP" > "/tmp/test-restore.tar.gz"

    tar -tzf "/tmp/test-restore.tar.gz" > /dev/null
    echo "✅ Backup integrity verified"

    # Cleanup
    rm -f "/tmp/$LATEST_BACKUP" "/tmp/test-restore.tar.gz"
else
    echo "❌ No backup found for ${DATE}"
    exit 1
fi
```

### Disaster Recovery Testing

```bash
#!/bin/bash
# scripts/test-disaster-recovery.sh

echo "🚨 Starting disaster recovery test"

# 1. Create test data
echo "📝 Creating test data..."
curl -X POST https://vault.yourdomain.com/api/accounts/register \
  -H "Content-Type: application/json" \
  -d '{"email":"test@example.com","masterPasswordHash":"test_hash"}'

# 2. Force backup
echo "💾 Forcing backup..."
docker exec vw_backup /scripts/backup-daily.sh

# 3. Simulate disaster (destroy container)
echo "💥 Simulating disaster..."
docker stop vaultwarden
docker rm vaultwarden
docker volume rm vaultwarden_vw_data

# 4. Restore from backup
echo "🔧 Restoring from backup..."
./scripts/restore-backup.sh production latest

# 5. Verify restoration
echo "✅ Verifying restoration..."
curl -f https://vault.yourdomain.com/alive

echo "🎉 Disaster recovery test completed successfully"
```

## 🔧 Maintenance Tasks

### Daily Tasks (Automated)

```yaml
# Crontab entries
0 2 * * * /opt/vaultwarden/scripts/backup-daily.sh
0 3 * * * /opt/vaultwarden/scripts/verify-backup.sh
0 4 * * * /opt/vaultwarden/scripts/cleanup-logs.sh
0 5 * * * /opt/vaultwarden/scripts/update-security-scans.sh
```

### Weekly Tasks

```bash
#!/bin/bash
# scripts/weekly-maintenance.sh

# Security updates
apt update && apt upgrade -y

# Docker cleanup
docker system prune -f

# Log rotation
logrotate /etc/logrotate.conf

# Certificate renewal check
certbot renew --dry-run

# Backup verification
./scripts/verify-backup.sh production

# Performance metrics collection
./scripts/collect-metrics.sh
```

### Monthly Tasks

```bash
#!/bin/bash
# scripts/monthly-maintenance.sh

# Full system audit
./scripts/security-audit.sh

# Backup restoration test
./scripts/test-disaster-recovery.sh

# Performance optimization
./scripts/optimize-database.sh

# Update dependencies
./scripts/update-dependencies.sh

# Review and rotate secrets
./scripts/rotate-secrets.sh
```

## 🔍 Troubleshooting Runbooks

### Application Won't Start

```bash
# Check container status
docker ps -a | grep vaultwarden

# Check logs
docker logs vaultwarden --tail 50

# Check configuration
docker exec vaultwarden cat /etc/vaultwarden.conf

# Common fixes
docker restart vaultwarden
docker system prune -f && docker-compose up -d
```

### Backup Issues

```bash
# Check backup service
docker logs vw_backup --tail 50

# Verify S3 connectivity
aws s3 ls s3://your-backup-bucket

# Test backup manually
docker exec vw_backup /scripts/backup-hourly.sh

# Check encryption key
echo $BACKUP_ENCRYPTION_KEY | wc -c  # Should be 32+ chars
```

### Performance Issues

```bash
# Check system resources
top
df -h
free -h

# Check application metrics
curl https://vault.yourdomain.com/metrics

# Database optimization
docker exec vaultwarden sqlite3 /data/db.sqlite3 "VACUUM;"

# Restart services
docker-compose restart
```

### SSL/TLS Issues

```bash
# Check certificate status
openssl s_client -connect vault.yourdomain.com:443 -servername vault.yourdomain.com

# Check certificate expiry
echo | openssl s_client -connect vault.yourdomain.com:443 2>/dev/null | openssl x509 -noout -dates

# Renew certificate
certbot renew --force-renewal

# Check nginx configuration
docker exec nginx-proxy nginx -t
```

## 📈 Performance Optimization

### Database Optimization

```sql
-- SQLite optimization queries
PRAGMA journal_mode=WAL;
PRAGMA synchronous=NORMAL;
PRAGMA cache_size=10000;
PRAGMA temp_store=memory;
VACUUM;
REINDEX;
```

### Container Optimization

```yaml
# docker-compose.yml optimizations
services:
  vaultwarden:
    deploy:
      resources:
        limits:
          memory: 512M
          cpus: "0.5"
        reservations:
          memory: 256M
          cpus: "0.25"
    healthcheck:
      test: ["CMD", "curl", "-f", "http://localhost:80/alive"]
      interval: 30s
      timeout: 10s
      retries: 3
```

### Network Optimization

```nginx
# nginx optimizations
worker_processes auto;
worker_connections 1024;

gzip on;
gzip_comp_level 6;
gzip_types text/plain text/css application/json application/javascript text/xml application/xml;

client_max_body_size 128M;
client_body_buffer_size 128k;
```

## 🔔 Incident Response

### Severity Levels

| Level             | Response Time | Description                           |
| ----------------- | ------------- | ------------------------------------- |
| **P0 - Critical** | 15 minutes    | Service completely down               |
| **P1 - High**     | 1 hour        | Major functionality impacted          |
| **P2 - Medium**   | 4 hours       | Minor functionality impacted          |
| **P3 - Low**      | 24 hours      | Cosmetic issues, enhancement requests |

### Incident Response Playbook

#### Step 1: Initial Response (0-15 minutes)

```bash
# Acknowledge incident
echo "Incident acknowledged at $(date)" >> /var/log/incidents.log

# Check service status
./scripts/health-check.sh production

# Gather initial information
./scripts/collect-debug-info.sh
```

#### Step 2: Assessment (15-30 minutes)

```bash
# Determine scope and impact
./scripts/incident-assessment.sh

# Check recent changes
git log --oneline --since="1 hour ago"

# Review monitoring dashboards
open https://grafana.yourdomain.com
```

#### Step 3: Resolution (varies by severity)

```bash
# Attempt quick fixes
./scripts/quick-fixes.sh

# If needed, rollback
git revert HEAD
./scripts/deploy.sh production

# Escalate if needed
./scripts/escalate-incident.sh
```

#### Step 4: Post-Incident (within 24 hours)

```bash
# Document incident
./scripts/create-incident-report.sh

# Schedule post-mortem
./scripts/schedule-postmortem.sh

# Implement preventive measures
./scripts/update-monitoring.sh
```

## 📋 Operations Checklist

### Daily Checklist

- [ ] Check backup completion status
- [ ] Review error logs and alerts
- [ ] Verify application health endpoints
- [ ] Monitor resource utilization
- [ ] Check security scan results

### Weekly Checklist

- [ ] Review performance metrics trends
- [ ] Test backup restoration procedure
- [ ] Update security patches
- [ ] Review and rotate logs
- [ ] Verify SSL certificate status

### Monthly Checklist

- [ ] Conduct disaster recovery test
- [ ] Review and update documentation
- [ ] Audit user access and permissions
- [ ] Optimize database and cleanup
- [ ] Review and update monitoring rules

---

[← Development Workflow](06-development-workflow.md) | [Troubleshooting →](08-troubleshooting.md)

# 🐛 Troubleshooting Guide

This comprehensive troubleshooting guide helps you diagnose and resolve common issues with ValkyrieVault.

## 🚨 Emergency Procedures

### Critical Service Down

```bash
# Quick diagnosis checklist
echo "🔍 Emergency Diagnosis Started: $(date)"

# 1. Check if services are running
echo "📊 Docker Services Status:"
docker ps -a | grep -E "(vaultwarden|nginx|backup)"

# 2. Check service health
echo "🏥 Health Check:"
curl -I https://vault.yourdomain.com/alive || echo "❌ Service unreachable"

# 3. Check recent logs
echo "📋 Recent Error Logs:"
docker logs vaultwarden --tail 50 --since 10m | grep -i error

# 4. Check system resources
echo "💾 System Resources:"
df -h | head -2
free -h
uptime

# 5. Quick restart attempt
echo "🔄 Attempting service restart"
docker-compose restart
```

### Data Recovery Emergency

```bash
#!/bin/bash
# Emergency data recovery procedure

echo "🚨 EMERGENCY DATA RECOVERY PROCEDURE"
echo "Timestamp: $(date)"

# Step 1: Stop all services to prevent data corruption
echo "🛑 Stopping all services..."
docker-compose down

# Step 2: Create emergency backup of current state
echo "📦 Creating emergency backup..."
tar -czf "/tmp/emergency-backup-$(date +%Y%m%d-%H%M%S).tar.gz" \
  /opt/vaultwarden/data

# Step 3: Identify latest good backup
echo "🔍 Identifying latest backup..."
LATEST_BACKUP=$(aws s3 ls s3://vaultwarden-prod-backups/daily/ | sort | tail -1 | awk '{print $4}')
echo "Latest backup: $LATEST_BACKUP"

# Step 4: Download and restore backup
echo "⬇️ Downloading backup..."
aws s3 cp "s3://vaultwarden-prod-backups/daily/$LATEST_BACKUP" "/tmp/"

echo "🔓 Decrypting backup..."
gpg --decrypt --batch --passphrase "$BACKUP_ENCRYPTION_KEY" \
  "/tmp/$LATEST_BACKUP" | tar -xzf - -C /opt/vaultwarden/

# Step 5: Restart services
echo "🚀 Restarting services..."
docker-compose up -d

# Step 6: Verify recovery
echo "✅ Verifying recovery..."
sleep 30
curl -f https://vault.yourdomain.com/alive && echo "Recovery successful" || echo "Recovery failed"
```

## 🔧 Infrastructure Issues

### Terraform/OpenTofu Problems

#### Error: State Lock

```bash
# Problem: Terraform state is locked
Error: Error acquiring the state lock: ConditionalCheckFailedException

# Solution 1: Check if another process is running
ps aux | grep terraform

# Solution 2: Force unlock (use carefully)
tofu force-unlock LOCK_ID

# Solution 3: If DynamoDB table issues
aws dynamodb scan --table-name terraform-state-lock --max-items 5
aws dynamodb delete-item --table-name terraform-state-lock --key '{"LockID":{"S":"LOCK_ID"}}'
```

#### Error: AWS Credentials

```bash
# Problem: Invalid AWS credentials
Error: NoCredentialsError: Unable to locate credentials

# Diagnosis
aws sts get-caller-identity

# Solutions
export AWS_ACCESS_KEY_ID=your_access_key
export AWS_SECRET_ACCESS_KEY=your_secret_key
export AWS_DEFAULT_REGION=eu-west-3

# Or reconfigure
aws configure

# Check IAM permissions
aws iam get-user
aws iam list-attached-user-policies --user-name your-username
```

#### Error: Resource Already Exists

```bash
# Problem: Resource conflicts
Error: ResourceInUseException: Table already exists

# Solution 1: Import existing resources
tofu import aws_s3_bucket.backup your-bucket-name
tofu import aws_dynamodb_table.lock terraform-state-lock

# Solution 2: Use different resource names
# Edit terraform.tfvars
project_name = "vaultwarden-v2"

# Solution 3: Destroy conflicting resources (careful!)
tofu destroy -target=aws_s3_bucket.backup
```

### AWS Service Issues

#### S3 Backup Failures

```bash
# Problem: S3 backup uploads failing

# Diagnosis
echo "🔍 Diagnosing S3 issues"
aws s3 ls s3://vaultwarden-prod-backups/ || echo "❌ Bucket access failed"

# Check bucket policy
aws s3api get-bucket-policy --bucket vaultwarden-prod-backups

# Test manual upload
echo "test" > /tmp/test.txt
aws s3 cp /tmp/test.txt s3://vaultwarden-prod-backups/test/

# Check service logs
docker logs vw_backup | grep -i s3

# Common solutions
# 1. Check IAM permissions
aws iam simulate-principal-policy \
  --policy-source-arn arn:aws:iam::ACCOUNT:user/backup-user \
  --action-names s3:PutObject \
  --resource-arns "arn:aws:s3:::vaultwarden-prod-backups/*"

# 2. Verify bucket region
aws s3api get-bucket-location --bucket vaultwarden-prod-backups

# 3. Check networking
curl -I https://s3.eu-west-3.amazonaws.com
```

#### Secrets Manager Issues

```bash
# Problem: Cannot retrieve secrets

# Diagnosis
aws secretsmanager describe-secret --secret-id vaultwarden-prod-config

# Test retrieval
aws secretsmanager get-secret-value --secret-id vaultwarden-prod-config

# Check permissions
aws logs describe-log-groups --log-group-name-prefix "/aws/secretsmanager"

# Common fixes
# 1. Recreate secret with proper permissions
aws secretsmanager update-secret --secret-id vaultwarden-prod-config \
  --description "Updated with proper permissions"

# 2. Check resource policy
aws secretsmanager describe-secret --secret-id vaultwarden-prod-config \
  --query 'ResourcePolicy'
```

## 🐳 Docker & Container Issues

### Container Won't Start

```bash
# Problem: Vaultwarden container fails to start

# Diagnosis steps
echo "🔍 Diagnosing container startup issues"

# 1. Check container status
docker ps -a | grep vaultwarden

# 2. Check logs
docker logs vaultwarden --tail 100

# 3. Check environment variables
docker exec vaultwarden env | grep -E "(DOMAIN|ADMIN_TOKEN|DATABASE_URL)"

# 4. Check file permissions
docker exec vaultwarden ls -la /data/

# 5. Check port conflicts
netstat -tulpn | grep :8080

# Common solutions
# Solution 1: Permission issues
sudo chown -R 65534:65534 /opt/vaultwarden/data
docker-compose restart vaultwarden

# Solution 2: Configuration issues
cat > /tmp/fixed.env << 'EOF'
DOMAIN=https://vault.yourdomain.com
ADMIN_TOKEN=your-admin-token
DATABASE_URL=sqlite:///data/db.sqlite3
WEBSOCKET_ENABLED=true
LOG_LEVEL=info
EOF
docker run --rm -v /opt/vaultwarden/data:/data --env-file /tmp/fixed.env vaultwarden/server

# Solution 3: Database corruption
docker exec vaultwarden sqlite3 /data/db.sqlite3 "PRAGMA integrity_check;"
# If corrupted, restore from backup
```

### Database Issues

```bash
# Problem: SQLite database corruption or issues

# Diagnosis
echo "🔍 Diagnosing database issues"

# 1. Check database file
docker exec vaultwarden ls -la /data/db.sqlite3

# 2. Database integrity check
docker exec vaultwarden sqlite3 /data/db.sqlite3 "PRAGMA integrity_check;"

# 3. Check database size
docker exec vaultwarden sqlite3 /data/db.sqlite3 "SELECT COUNT(*) FROM users;"

# 4. Check recent errors
docker logs vaultwarden | grep -i "database\|sqlite\|sql"

# Solutions
# Solution 1: Database optimization
docker exec vaultwarden sqlite3 /data/db.sqlite3 "
  PRAGMA journal_mode=WAL;
  PRAGMA synchronous=NORMAL;
  PRAGMA cache_size=10000;
  VACUUM;
  REINDEX;
"

# Solution 2: Backup current and restore from backup
docker exec vaultwarden cp /data/db.sqlite3 /data/db.sqlite3.backup
./scripts/restore-backup.sh production latest

# Solution 3: Database rescue operations
docker exec vaultwarden sqlite3 /data/db.sqlite3 "
  .output /data/rescue.sql
  .dump
"
# Then restore from dump if needed
```

### Network & SSL Issues

```bash
# Problem: SSL certificate or networking issues

# Diagnosis checklist
echo "🔍 Diagnosing network and SSL issues"

# 1. Check nginx proxy status
docker logs nginx-proxy --tail 50

# 2. Check SSL certificate
echo | openssl s_client -connect vault.yourdomain.com:443 -servername vault.yourdomain.com | openssl x509 -noout -dates

# 3. Check DNS resolution
dig vault.yourdomain.com
nslookup vault.yourdomain.com 8.8.8.8

# 4. Check port accessibility
telnet vault.yourdomain.com 443
curl -I http://vault.yourdomain.com

# 5. Check certificate logs
docker logs nginx-proxy-letsencrypt --tail 50

# Solutions
# Solution 1: Force certificate renewal
docker exec nginx-proxy-letsencrypt /app/letsencrypt_service --force

# Solution 2: Check nginx configuration
docker exec nginx-proxy nginx -t
docker exec nginx-proxy cat /etc/nginx/conf.d/default.conf

# Solution 3: Restart networking stack
docker network ls
docker network prune -f
docker-compose down && docker-compose up -d

# Solution 4: Firewall issues
sudo ufw status
sudo iptables -L | grep -E "(80|443)"
```

## 🔄 Backup & Recovery Issues

### Backup Service Failures

```bash
# Problem: Automated backups are failing

# Diagnosis
echo "🔍 Diagnosing backup service issues"

# 1. Check backup service status
docker ps | grep backup
docker logs vw_backup --tail 100

# 2. Check cron jobs
docker exec vw_backup crontab -l
docker exec vw_backup ps aux | grep crond

# 3. Test manual backup
docker exec vw_backup /scripts/backup-hourly.sh

# 4. Check S3 connectivity
docker exec vw_backup aws s3 ls s3://vaultwarden-prod-backups/

# Solutions
# Solution 1: Fix cron service
docker exec vw_backup sh -c "
  killall crond 2>/dev/null || true
  crond -f &
  echo 'Cron restarted'
"

# Solution 2: Fix permissions
docker exec vw_backup chmod +x /scripts/*.sh
docker exec vw_backup ls -la /scripts/

# Solution 3: Fix encryption
docker exec vw_backup sh -c "
  echo 'test' | gpg --symmetric --cipher-algo AES256 --passphrase '$BACKUP_ENCRYPTION_KEY' --batch
"

# Solution 4: Manual backup and restore test
./scripts/backup-manual.sh
./scripts/test-restore.sh
```

### Backup Corruption

```bash
# Problem: Backup files are corrupted or unreadable

# Diagnosis
echo "🔍 Testing backup integrity"

# 1. Download recent backups
aws s3 sync s3://vaultwarden-prod-backups/daily/ /tmp/backup-test/ --exclude "*" --include "*$(date +%Y%m%d)*"

# 2. Test decryption
for backup in /tmp/backup-test/*.gpg; do
  echo "Testing $backup"
  gpg --decrypt --batch --passphrase "$BACKUP_ENCRYPTION_KEY" "$backup" > /dev/null && echo "✅ OK" || echo "❌ FAILED"
done

# 3. Test extraction
LATEST_BACKUP=$(ls -t /tmp/backup-test/*.gpg | head -1)
gpg --decrypt --batch --passphrase "$BACKUP_ENCRYPTION_KEY" "$LATEST_BACKUP" | tar -tf - > /dev/null && echo "✅ Archive OK" || echo "❌ Archive corrupted"

# Solutions
# Solution 1: Find last good backup
for i in {1..7}; do
  DATE=$(date -d "$i days ago" +%Y%m%d)
  aws s3 ls s3://vaultwarden-prod-backups/daily/ | grep $DATE
done

# Solution 2: Cross-verify with hourly backups
aws s3 ls s3://vaultwarden-prod-backups/hourly/ | tail -10

# Solution 3: Emergency manual backup
tar -czf "/tmp/emergency-$(date +%Y%m%d-%H%M%S).tar.gz" /opt/vaultwarden/data
gpg --symmetric --cipher-algo AES256 --passphrase "$BACKUP_ENCRYPTION_KEY" "/tmp/emergency-*.tar.gz"
```

## 🔐 Authentication & Access Issues

### Admin Panel Access

```bash
# Problem: Cannot access admin panel

# Diagnosis
echo "🔍 Diagnosing admin panel access"

# 1. Check admin token
aws secretsmanager get-secret-value --secret-id vaultwarden-prod-config --query SecretString --output text | jq -r .admin_token

# 2. Check admin panel URL
curl -I https://vault.yourdomain.com/admin/

# 3. Check rate limiting
docker logs nginx-proxy | grep -i "limiting\|429"

# Solutions
# Solution 1: Reset admin token
NEW_TOKEN=$(openssl rand -hex 32)
aws secretsmanager update-secret --secret-id vaultwarden-prod-config \
  --secret-string "$(aws secretsmanager get-secret-value --secret-id vaultwarden-prod-config --query SecretString --output text | jq --arg token "$NEW_TOKEN" '.admin_token = $token')"

# Restart application to pick up new token
docker-compose restart vaultwarden

# Solution 2: Bypass rate limiting temporarily
docker exec nginx-proxy sed -i 's/limit_req/#limit_req/g' /etc/nginx/conf.d/default.conf
docker exec nginx-proxy nginx -s reload

# Solution 3: Direct access (emergency)
docker exec vaultwarden curl -H "Admin-Token: $ADMIN_TOKEN" http://localhost:80/admin/
```

### User Login Issues

```bash
# Problem: Users cannot log in

# Diagnosis
echo "🔍 Diagnosing user login issues"

# 1. Check recent authentication logs
docker logs vaultwarden | grep -i "login\|auth\|failed" | tail -20

# 2. Check database connectivity
docker exec vaultwarden sqlite3 /data/db.sqlite3 "SELECT COUNT(*) FROM users;"

# 3. Test API endpoints
curl -X POST https://vault.yourdomain.com/api/accounts/prelogin \
  -H "Content-Type: application/json" \
  -d '{"email":"test@example.com"}'

# Solutions
# Solution 1: Check password iterations
docker exec vaultwarden sqlite3 /data/db.sqlite3 "
  SELECT email, password_iterations FROM users LIMIT 5;
"

# Solution 2: Reset user password (emergency)
# Generate new password hash
NEW_HASH=$(echo -n "newpassword" | argon2 $(openssl rand -hex 32) -id -t 3 -m 65536 -p 4 -l 32)

docker exec vaultwarden sqlite3 /data/db.sqlite3 "
  UPDATE users SET password_hash = '$NEW_HASH' WHERE email = 'user@example.com';
"

# Solution 3: Check WebSocket connectivity
curl -H "Connection: Upgrade" \
     -H "Upgrade: websocket" \
     -H "Sec-WebSocket-Version: 13" \
     -H "Sec-WebSocket-Key: test" \
     https://vault.yourdomain.com/notifications/hub
```

## 📊 Performance Issues

### High CPU Usage

```bash
# Problem: High CPU usage

# Diagnosis
echo "🔍 Diagnosing high CPU usage"

# 1. Check current CPU usage
docker stats --no-stream
top -p $(docker inspect --format '{{.State.Pid}}' vaultwarden)

# 2. Check for runaway processes
docker exec vaultwarden ps aux

# 3. Check application logs for errors
docker logs vaultwarden | grep -i "error\|panic\|deadlock"

# Solutions
# Solution 1: Restart application
docker-compose restart vaultwarden

# Solution 2: Check database optimization
docker exec vaultwarden sqlite3 /data/db.sqlite3 "
  PRAGMA optimize;
  PRAGMA vacuum;
  ANALYZE;
"

# Solution 3: Resource limits
cat >> docker-compose.override.yml << 'EOF'
version: '3.8'
services:
  vaultwarden:
    deploy:
      resources:
        limits:
          cpus: '1.0'
          memory: 512M
        reservations:
          cpus: '0.5'
          memory: 256M
EOF
docker-compose up -d
```

### Memory Issues

```bash
# Problem: High memory usage or out of memory

# Diagnosis
echo "🔍 Diagnosing memory issues"

# 1. Check memory usage
free -h
docker stats --no-stream
cat /proc/meminfo

# 2. Check for memory leaks
docker exec vaultwarden ps -o pid,ppid,cmd,%mem,%cpu --sort=-%mem

# 3. Check swap usage
swapon --show
cat /proc/swaps

# Solutions
# Solution 1: Clear caches
sync && echo 3 > /proc/sys/vm/drop_caches

# Solution 2: Optimize SQLite memory usage
docker exec vaultwarden sqlite3 /data/db.sqlite3 "
  PRAGMA cache_size = 2000;
  PRAGMA temp_store = memory;
  PRAGMA journal_mode = WAL;
"

# Solution 3: Add swap (if none exists)
sudo fallocate -l 2G /swapfile
sudo chmod 600 /swapfile
sudo mkswap /swapfile
sudo swapon /swapfile
echo '/swapfile none swap sw 0 0' >> /etc/fstab
```

### Disk Space Issues

```bash
# Problem: Running out of disk space

# Diagnosis
echo "🔍 Diagnosing disk space issues"

# 1. Check disk usage
df -h
du -sh /opt/vaultwarden/*
du -sh /var/lib/docker/*

# 2. Find large files
find /opt/vaultwarden -size +100M -ls
docker system df

# Solutions
# Solution 1: Clean Docker resources
docker system prune -af --volumes
docker image prune -af

# Solution 2: Clean old logs
find /var/log -name "*.log" -mtime +30 -delete
docker logs vaultwarden 2>/dev/null | tail -1000 > /tmp/vw.log
# Truncate logs in container if needed

# Solution 3: Archive old backups
aws s3 cp s3://vaultwarden-prod-backups/daily/ s3://vaultwarden-archive-backups/daily/ --recursive
# Then delete old backups based on retention policy
```

## 🛠️ Advanced Troubleshooting

### Debug Mode Activation

```bash
#!/bin/bash
# Enable debug mode for troubleshooting

echo "🐛 Activating debug mode"

# 1. Enable debug logging
cat >> /opt/vaultwarden/.env << 'EOF'
LOG_LEVEL=debug
EXTENDED_LOGGING=true
RUST_BACKTRACE=full
EOF

# 2. Restart with debug
docker-compose restart vaultwarden

# 3. Start log monitoring
docker logs -f vaultwarden &

# 4. Enable SQL query logging (careful - sensitive data!)
docker exec vaultwarden sqlite3 /data/db.sqlite3 "
  PRAGMA query_only = ON;
  .log stderr
"

echo "🐛 Debug mode active - monitor logs and disable when done"
```

### Network Diagnostics

```bash
#!/bin/bash
# Comprehensive network diagnostics

echo "🌐 Running network diagnostics"

# 1. Container network
docker network ls
docker network inspect vaultwarden_vaultwarden_net

# 2. Port connectivity
ss -tulpn | grep -E "(80|443|8080|3012)"

# 3. External connectivity
curl -I https://httpbin.org/status/200
dig @8.8.8.8 vault.yourdomain.com

# 4. Internal service communication
docker exec vaultwarden curl -I http://nginx-proxy:80
docker exec nginx-proxy curl -I http://vaultwarden:80

# 5. SSL certificate chain
echo | openssl s_client -connect vault.yourdomain.com:443 -showcerts
```

### Performance Profiling

```bash
#!/bin/bash
# Performance profiling and analysis

echo "📊 Starting performance profile"

# 1. System performance snapshot
iostat -x 1 5 > /tmp/iostat.log &
vmstat 1 5 > /tmp/vmstat.log &

# 2. Application performance
docker exec vaultwarden sh -c 'echo "SELECT COUNT(*) as users FROM users;" | sqlite3 /data/db.sqlite3'
docker exec vaultwarden sh -c 'echo ".timer on" ".stats on" "SELECT * FROM ciphers LIMIT 1;" | sqlite3 /data/db.sqlite3'

# 3. Container resource usage over time
for i in {1..60}; do
  docker stats --no-stream --format "table {{.Name}}\t{{.CPUPerc}}\t{{.MemUsage}}"
  sleep 1
done > /tmp/docker-stats.log &

echo "📊 Profiling running - check /tmp/*.log files"
```

---

[← Deployment](05-deployment.md) | [Security →](09-security.md)

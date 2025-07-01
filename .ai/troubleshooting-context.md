# 🐛 Troubleshooting Context for Vaultwarden Infrastructure

## Common Problem Categories

### 1. Application Issues

#### Vaultwarden Container Problems

```yaml
symptoms:
  - Container won't start
  - Application crashes randomly
  - Users can't login
  - Admin panel inaccessible
  - WebSocket connection failures

diagnostics:
  logs: docker logs vaultwarden --tail 100
  health: curl -f http://localhost:8080/alive
  config: docker exec vaultwarden env | grep -E "(DOMAIN|ADMIN_TOKEN|DATABASE_URL)"
  database: docker exec vaultwarden sqlite3 /data/db.sqlite3 "PRAGMA integrity_check;"
  ports: netstat -tulpn | grep :8080

common_fixes:
  permission_issues:
    - chown -R 65534:65534 /opt/vaultwarden/data
    - docker-compose restart vaultwarden

  database_corruption:
    - sqlite3 /data/db.sqlite3 "PRAGMA integrity_check;"
    - Restore from backup if corrupted

  configuration_errors:
    - Check DOMAIN matches actual URL
    - Verify ADMIN_TOKEN is set correctly
    - Ensure DATABASE_URL path is correct
```

#### Database Issues

```sql
-- Common database diagnostics
PRAGMA integrity_check;
PRAGMA quick_check;
PRAGMA optimize;

-- Check user count and activity
SELECT COUNT(*) as total_users FROM users;
SELECT COUNT(*) as total_ciphers FROM ciphers;
SELECT COUNT(*) as failed_logins FROM event_logs WHERE event_type = 1003;

-- Database optimization
PRAGMA journal_mode=WAL;
PRAGMA synchronous=NORMAL;
PRAGMA cache_size=10000;
VACUUM;
REINDEX;
```

### 2. Infrastructure Issues

#### Terraform/OpenTofu Problems

```yaml
state_lock_issues:
  symptoms: "Error acquiring the state lock"
  diagnostics:
    - ps aux | grep terraform
    - aws dynamodb scan --table-name terraform-state-lock
  solutions:
    - tofu force-unlock LOCK_ID
    - aws dynamodb delete-item --table-name terraform-state-lock --key '{"LockID":{"S":"LOCK_ID"}}'

resource_conflicts:
  symptoms: "ResourceInUseException: Table already exists"
  solutions:
    - tofu import aws_s3_bucket.backup bucket-name
    - Use different resource names in terraform.tfvars
    - tofu destroy -target=aws_s3_bucket.backup (careful!)

aws_credentials:
  symptoms: "NoCredentialsError: Unable to locate credentials"
  diagnostics: aws sts get-caller-identity
  solutions:
    - aws configure
    - export AWS_ACCESS_KEY_ID=xxx
    - Check IAM permissions
```

#### Container Platform Issues

```yaml
docker_socket_issues:
  symptoms: "Cannot connect to Docker daemon"
  solutions:
    - sudo systemctl start docker
    - sudo usermod -aG docker $USER
    - Check /var/run/docker.sock permissions

container_networking:
  symptoms: "Service unreachable between containers"
  diagnostics:
    - docker network ls
    - docker network inspect vaultwarden_vaultwarden_net
    - docker exec container ping other_container
  solutions:
    - docker network prune
    - docker-compose down && docker-compose up -d
    - Check service names in docker-compose.yml

volume_mounting:
  symptoms: "No such file or directory in container"
  diagnostics:
    - docker volume ls
    - docker volume inspect vaultwarden_vw_data
    - ls -la /opt/vaultwarden/data
  solutions:
    - Create directory: mkdir -p /opt/vaultwarden/data
    - Fix permissions: chown 65534:65534 /opt/vaultwarden/data
    - Check bind mount paths in docker-compose.yml
```

### 3. Network and SSL Issues

#### SSL Certificate Problems

```bash
# Certificate diagnostics
openssl s_client -connect vault.yourdomain.com:443 -servername vault.yourdomain.com
echo | openssl s_client -connect vault.yourdomain.com:443 2>/dev/null | openssl x509 -noout -dates

# Let's Encrypt issues
docker logs nginx-proxy-letsencrypt --tail 50
docker exec nginx-proxy-letsencrypt /app/letsencrypt_service --force

# DNS validation
dig vault.yourdomain.com
nslookup vault.yourdomain.com 8.8.8.8

# Common solutions
solutions:
  dns_issues:
    - Wait for DNS propagation (up to 48 hours)
    - Check domain provider DNS settings
    - Use DNS checker tools online

  rate_limiting:
    - Let's Encrypt has rate limits (5 per week for same domain)
    - Use staging environment for testing
    - Wait for rate limit reset

  firewall_blocking:
    - Check UFW status: ufw status
    - Verify ports 80, 443 are open
    - Check cloud provider firewall rules
```

#### Network Connectivity

```bash
# Port accessibility testing
telnet vault.yourdomain.com 443
curl -I http://vault.yourdomain.com
curl -I https://vault.yourdomain.com

# Internal container communication
docker exec nginx-proxy curl -I http://vaultwarden:80
docker exec vaultwarden curl -I http://nginx-proxy:80

# Firewall diagnostics
ufw status verbose
iptables -L | grep -E "(80|443|8080)"
netstat -tulpn | grep -E ":(80|443|8080)"

# Common network issues
issues:
  port_conflicts:
    - netstat -tulpn | grep :80
    - sudo systemctl stop apache2  # If Apache is running
    - Change port in docker-compose.yml

  firewall_blocking:
    - ufw allow 80/tcp
    - ufw allow 443/tcp
    - ufw reload

  dns_resolution:
    - /etc/hosts entry for testing
    - Check /etc/resolv.conf
    - Restart systemd-resolved
```

### 4. Backup and Storage Issues

#### Backup Service Problems

```yaml
backup_failures:
  symptoms:
    - No backups in S3 bucket
    - Backup service container crashes
    - Encryption/decryption errors

  diagnostics:
    logs: docker logs vw_backup --tail 100
    manual_test: docker exec vw_backup /scripts/backup-hourly.sh
    s3_connectivity: aws s3 ls s3://vaultwarden-prod-backups/
    encryption_test: echo "test" | gpg --symmetric --passphrase "$BACKUP_ENCRYPTION_KEY"

  common_solutions:
    cron_service:
      - docker exec vw_backup killall crond && crond -f &
      - docker exec vw_backup crontab -l

    aws_permissions:
      - aws iam simulate-principal-policy --policy-source-arn arn:aws:iam::ACCOUNT:user/backup-user --action-names s3:PutObject
      - Check bucket region matches configuration

    encryption_keys:
      - Verify BACKUP_ENCRYPTION_KEY is 32+ characters
      - Test GPG encryption manually
      - Rotate keys if compromised
```

#### Storage Space Issues

```bash
# Disk space monitoring
df -h
du -sh /opt/vaultwarden/*
du -sh /var/lib/docker/*

# Find large files
find /opt/vaultwarden -size +100M -ls
docker system df

# Cleanup procedures
cleanup_commands:
  docker_cleanup:
    - docker system prune -af --volumes
    - docker image prune -af

  log_cleanup:
    - find /var/log -name "*.log" -mtime +30 -delete
    - journalctl --vacuum-time=30d

  backup_archival:
    - aws s3 cp s3://vaultwarden-prod-backups/daily/ s3://archive-bucket/
    - Apply lifecycle policies for automatic deletion
```

### 5. Performance Issues

#### Memory and CPU Problems

```bash
# Resource monitoring
docker stats --no-stream
free -h
top -p $(docker inspect --format '{{.State.Pid}}' vaultwarden)
iostat -x 1 5

# Memory issues
memory_problems:
  high_usage:
    - Check for memory leaks in logs
    - Restart containers: docker-compose restart
    - Add swap if none exists
    - Optimize SQLite: PRAGMA cache_size = 2000;

  out_of_memory:
    - Increase VPS memory
    - Add resource limits to docker-compose.yml
    - Enable swap: fallocate -l 2G /swapfile

# CPU issues
cpu_problems:
  high_usage:
    - Check for infinite loops in logs
    - Database optimization: PRAGMA optimize; VACUUM;
    - Check for runaway processes: docker exec vaultwarden ps aux

  slow_response:
    - Enable database WAL mode: PRAGMA journal_mode=WAL;
    - Check network latency: ping vault.yourdomain.com
    - Review nginx access logs for slow queries
```

### 6. Security Incidents

#### Failed Login Detection

```bash
# Monitor authentication failures
tail -f /var/log/auth.log | grep "Failed password"
docker logs vaultwarden | grep -i "invalid\|failed\|error" | tail -20

# Brute force protection
grep "Failed password" /var/log/auth.log | grep "$(date '+%b %d')" | wc -l

# IP blocking (fail2ban)
fail2ban-client status sshd
fail2ban-client set sshd banip OFFENDING_IP
```

#### Compromise Response

```yaml
incident_response:
  immediate_actions:
    - Isolate system: ufw deny in
    - Stop services: docker-compose down
    - Preserve evidence: docker logs vaultwarden > incident-$(date +%Y%m%d-%H%M%S).log

  investigation:
    - Check recent logins: last | head -10
    - Review admin panel access logs
    - Examine file integrity: aide --check
    - Network analysis: netstat -tulpn

  recovery:
    - Rotate all secrets and tokens
    - Restore from known good backup
    - Update security measures
    - Document incident
```

## Debugging Workflows

### Systematic Troubleshooting Process

#### 1. Initial Assessment (5 minutes)

```bash
# Quick health check
curl -f https://vault.yourdomain.com/alive || echo "Health check failed"
docker ps | grep -E "(vaultwarden|nginx|backup)"
df -h | head -2
free -h
uptime
```

#### 2. Service-Level Diagnostics (10 minutes)

```bash
# Container logs
docker logs vaultwarden --tail 50 --since 10m | grep -i error
docker logs nginx-proxy --tail 50 --since 10m | grep -i error
docker logs vw_backup --tail 50 --since 10m | grep -i error

# Service connectivity
docker exec vaultwarden curl -f http://localhost:80/alive
docker exec nginx-proxy curl -f http://vaultwarden:80/alive
```

#### 3. Deep Diagnostics (30 minutes)

```bash
# Database analysis
docker exec vaultwarden sqlite3 /data/db.sqlite3 "PRAGMA integrity_check; PRAGMA quick_check;"

# Network analysis
ss -tulpn | grep -E ":(80|443|8080|3012)"
iptables -L | grep -E "(80|443)"

# Security analysis
fail2ban-client status
grep "Failed\|Invalid\|Illegal" /var/log/auth.log | tail -10

# Resource analysis
docker exec vaultwarden ps aux
iostat -x 1 3
```

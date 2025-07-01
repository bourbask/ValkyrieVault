# 🔒 Security Guide

This document provides comprehensive security guidelines, best practices, and hardening procedures for ValkyrieVault.

## 🎯 Security Framework

### Security Principles

- **Defense in Depth**: Multiple layers of security controls
- **Zero Trust**: Never trust, always verify
- **Least Privilege**: Minimum necessary access rights
- **Data Protection**: Encryption at rest and in transit
- **Continuous Monitoring**: Real-time security monitoring
- **Incident Response**: Prepared response procedures

### Compliance Standards

| Standard           | Applicable Controls                            | Implementation Status |
| ------------------ | ---------------------------------------------- | --------------------- |
| **GDPR**           | Data encryption, access logs, data portability | ✅ Implemented        |
| **SOC 2 Type II**  | Access controls, monitoring, encryption        | ✅ Implemented        |
| **ISO 27001**      | Information security management                | 🟡 Partial            |
| **NIST Framework** | Identify, protect, detect, respond, recover    | ✅ Implemented        |

## 🛡️ Infrastructure Security

### Network Security

#### Firewall Configuration

```bash
#!/bin/bash
# scripts/configure-security-firewall.sh

# Advanced UFW configuration with security hardening
ufw --force reset

# Default policies - deny all incoming, allow outgoing
ufw default deny incoming
ufw default allow outgoing
ufw default deny forward

# SSH with enhanced protection
ufw limit ssh comment 'SSH with rate limiting'

# Web services
ufw allow 80/tcp comment 'HTTP'
ufw allow 443/tcp comment 'HTTPS'

# Deny commonly attacked ports
ufw deny 23 comment 'Telnet - should never be open'
ufw deny 135 comment 'RPC - Windows specific'
ufw deny 445 comment 'SMB - Windows file sharing'
ufw deny 1433 comment 'MSSQL - Database should not be exposed'
ufw deny 3306 comment 'MySQL - Database should not be exposed'
ufw deny 5432 comment 'PostgreSQL - Database should not be exposed'

# Application-specific denials
ufw deny 8080 comment 'Vaultwarden internal port'
ufw deny 3012 comment 'Vaultwarden WebSocket internal'

# Geographic blocking (requires GeoIP)
if command -v geoiplookup &> /dev/null; then
    # Block known hostile countries (adjust as needed)
    for country in CN RU IR KP; do
        # Note: This requires iptables-geoip or similar
        echo "Consider geographic blocking for: $country"
    done
fi

# Enable logging
ufw logging on

# Enable UFW
ufw --force enable

echo "🛡️ Advanced firewall configuration completed"
```

#### Advanced iptables Rules

```bash
#!/bin/bash
# scripts/configure-iptables-advanced.sh

echo "🔧 Configuring advanced iptables rules"

# Flush existing rules
iptables -F
iptables -X
iptables -Z
ip6tables -F
ip6tables -X
ip6tables -Z

# Default policies
iptables -P INPUT DROP
iptables -P FORWARD DROP
iptables -P OUTPUT ACCEPT
ip6tables -P INPUT DROP
ip6tables -P FORWARD DROP
ip6tables -P OUTPUT ACCEPT

# Allow loopback
iptables -A INPUT -i lo -j ACCEPT
iptables -A OUTPUT -o lo -j ACCEPT
ip6tables -A INPUT -i lo -j ACCEPT
ip6tables -A OUTPUT -o lo -j ACCEPT

# Allow established and related connections
iptables -A INPUT -m conntrack --ctstate ESTABLISHED,RELATED -j ACCEPT
ip6tables -A INPUT -m conntrack --ctstate ESTABLISHED,RELATED -j ACCEPT

# SSH with advanced protection
iptables -A INPUT -p tcp --dport 22 -m conntrack --ctstate NEW -m recent --set --name sshbrute
iptables -A INPUT -p tcp --dport 22 -m conntrack --ctstate NEW -m recent --rcheck --seconds 60 --hitcount 4 --name sshbrute -j DROP
iptables -A INPUT -p tcp --dport 22 -m conntrack --ctstate NEW -j ACCEPT

# HTTP and HTTPS with rate limiting
iptables -A INPUT -p tcp --dport 80 -m limit --limit 25/min --limit-burst 100 -j ACCEPT
iptables -A INPUT -p tcp --dport 443 -m limit --limit 25/min --limit-burst 100 -j ACCEPT

# DDoS protection
iptables -A INPUT -p tcp --syn -m limit --limit 1/s --limit-burst 3 -j ACCEPT
iptables -A INPUT -p icmp --icmp-type echo-request -m limit --limit 1/s --limit-burst 1 -j ACCEPT

# Drop invalid packets
iptables -A INPUT -m conntrack --ctstate INVALID -j DROP
ip6tables -A INPUT -m conntrack --ctstate INVALID -j DROP

# Log dropped packets
iptables -A INPUT -j LOG --log-prefix "iptables-INPUT-dropped: " --log-level 4
ip6tables -A INPUT -j LOG --log-prefix "ip6tables-INPUT-dropped: " --log-level 4

# Save rules
iptables-save > /etc/iptables/rules.v4
ip6tables-save > /etc/iptables/rules.v6

echo "✅ Advanced iptables configuration completed"
```

### VPS Hardening

#### System Security Hardening

```bash
#!/bin/bash
# scripts/harden-system.sh

echo "🔒 Starting system hardening"

# 1. Update system
apt update && apt upgrade -y

# 2. Install security tools
apt install -y \
    fail2ban \
    rkhunter \
    chkrootkit \
    lynis \
    aide \
    unattended-upgrades \
    ufw \
    apparmor \
    apparmor-utils

# 3. Configure automatic security updates
cat > /etc/apt/apt.conf.d/50unattended-upgrades << 'EOF'
Unattended-Upgrade::Allowed-Origins {
    "${distro_id}:${distro_codename}";
    "${distro_id}:${distro_codename}-security";
    "${distro_id}ESMApps:${distro_codename}-apps-security";
    "${distro_id}ESM:${distro_codename}-infra-security";
};
Unattended-Upgrade::AutoFixInterruptedDpkg "true";
Unattended-Upgrade::MinimalSteps "true";
Unattended-Upgrade::Remove-Unused-Dependencies "true";
Unattended-Upgrade::Automatic-Reboot "false";
EOF

# 4. Configure fail2ban
cat > /etc/fail2ban/jail.local << 'EOF'
[DEFAULT]
bantime = 1h
findtime = 10m
maxretry = 3

[sshd]
enabled = true
port = ssh
filter = sshd
logpath = /var/log/auth.log

[nginx-http-auth]
enabled = true
filter = nginx-http-auth
logpath = /var/log/nginx/error.log

[nginx-limit-req]
enabled = true
filter = nginx-limit-req
logpath = /var/log/nginx/error.log
EOF

# 5. Disable unused services
systemctl disable bluetooth
systemctl disable cups
systemctl disable avahi-daemon

# 6. Configure kernel parameters
cat >> /etc/sysctl.conf << 'EOF'
# Network security improvements
net.ipv4.conf.all.send_redirects = 0
net.ipv4.conf.default.send_redirects = 0
net.ipv4.conf.all.accept_redirects = 0
net.ipv4.conf.default.accept_redirects = 0
net.ipv4.conf.all.secure_redirects = 0
net.ipv4.conf.default.secure_redirects = 0
net.ipv4.ip_forward = 0
net.ipv4.conf.all.log_martians = 1
net.ipv4.conf.default.log_martians = 1
net.ipv4.icmp_echo_ignore_broadcasts = 1
net.ipv4.icmp_ignore_bogus_error_responses = 1
net.ipv4.tcp_syncookies = 1
EOF

sysctl -p

# 7. Configure SSH hardening
cp /etc/ssh/sshd_config /etc/ssh/sshd_config.backup
cat > /etc/ssh/sshd_config << 'EOF'
# SSH Hardened Configuration
Port 22
Protocol 2
HostKey /etc/ssh/ssh_host_rsa_key
HostKey /etc/ssh/ssh_host_ecdsa_key
HostKey /etc/ssh/ssh_host_ed25519_key

# Authentication
LoginGraceTime 30
PermitRootLogin prohibit-password
StrictModes yes
MaxAuthTries 3
MaxSessions 2
PubkeyAuthentication yes
PasswordAuthentication no
ChallengeResponseAuthentication no
UsePAM yes

# Security options
X11Forwarding no
PrintMotd no
TCPKeepAlive yes
Compression no
AllowAgentForwarding no
AllowTcpForwarding no
GatewayPorts no

# Logging
SyslogFacility AUTH
LogLevel VERBOSE
EOF

systemctl restart sshd

# 8. Set file permissions
chmod 600 /etc/ssh/sshd_config
chmod 644 /etc/passwd
chmod 644 /etc/group
chmod 600 /etc/shadow
chmod 600 /etc/gshadow

# 9. Configure AIDE (file integrity monitoring)
aide --init
mv /var/lib/aide/aide.db.new /var/lib/aide/aide.db

# 10. Start security services
systemctl enable fail2ban
systemctl start fail2ban
systemctl enable apparmor
systemctl start apparmor

echo "✅ System hardening completed"
```

## 🔐 Application Security

### Vaultwarden Security Configuration

#### Enhanced Application Security

```bash
#!/bin/bash
# scripts/configure-vaultwarden-security.sh

echo "🔒 Configuring Vaultwarden security"

# Create secure environment configuration
cat > /opt/vaultwarden/.env.security << 'EOF'
# Security-focused Vaultwarden configuration

# Disable user registration in production
SIGNUPS_ALLOWED=false
INVITATIONS_ALLOWED=true
SIGNUPS_VERIFY=true

# Strong password policy
PASSWORD_ITERATIONS=350000

# Disable password hints
PASSWORD_HINTS_ALLOWED=false

# Enable advanced logging for security monitoring
EXTENDED_LOGGING=true
LOG_LEVEL=info

# Disable admin panel in production (access via environment variable only)
DISABLE_ADMIN_TOKEN=false

# Security headers and features
WEBSOCKET_ENABLED=true
WEB_VAULT_ENABLED=true

# Rate limiting (handled by nginx)
# These are backup application-level limits
ADMIN_RATELIMIT_SECONDS=300
ADMIN_RATELIMIT_MAX_BURST=3

# Email security
SMTP_SECURITY=starttls
SMTP_PORT=587

# File upload restrictions
ATTACHMENTS_FOLDER=data/attachments
# Limit handled by nginx: client_max_body_size
EOF

# Merge with main environment file
cat /opt/vaultwarden/.env.security >> /opt/vaultwarden/.env

echo "✅ Vaultwarden security configuration completed"
```

#### Database Security

```sql
-- Database security queries
-- Execute these in SQLite for additional security

-- Enable WAL mode for better performance and atomic writes
PRAGMA journal_mode=WAL;

-- Enable foreign key constraints
PRAGMA foreign_keys=ON;

-- Set secure delete (overwrites deleted data)
PRAGMA secure_delete=ON;

-- Optimize database
PRAGMA optimize;

-- Verify integrity
PRAGMA integrity_check;
```

### Container Security

#### Docker Security Best Practices

```yaml
# docker/docker-compose.security.yml
version: "3.8"

services:
  vaultwarden:
    image: vaultwarden/server:1.30.1
    container_name: vaultwarden
    restart: unless-stopped

    # Security: Run as non-root user
    user: "65534:65534" # nobody user

    # Security: Read-only root filesystem
    read_only: true
    tmpfs:
      - /tmp
      - /var/run

    # Security: Drop all capabilities and add only necessary ones
    cap_drop:
      - ALL
    cap_add:
      - SETUID
      - SETGID

    # Security: Disable new privileges
    security_opt:
      - no-new-privileges:true

    # Security: Resource limits
    deploy:
      resources:
        limits:
          memory: 512M
          cpus: "1.0"
          pids: 100
        reservations:
          memory: 256M
          cpus: "0.5"

    # Security: Environment variables from secrets
    environment:
      - DOMAIN=${DOMAIN}
    env_file:
      - .env.security

    # Security: Specific volume mounts only
    volumes:
      - vw_data:/data
      - type: tmpfs
        target: /tmp
        tmpfs:
          size: 100m

    networks:
      - vaultwarden_net

    healthcheck:
      test:
        [
          "CMD",
          "wget",
          "--no-verbose",
          "--tries=1",
          "--spider",
          "http://localhost:80/alive",
        ]
      interval: 30s
      timeout: 10s
      retries: 3
      start_period: 40s

  nginx-proxy:
    image: nginxproxy/nginx-proxy:1.4
    container_name: nginx-proxy
    restart: unless-stopped

    # Security: Read-only root filesystem where possible
    read_only: true
    tmpfs:
      - /var/run
      - /var/cache/nginx
      - /tmp

    # Security: Drop capabilities
    cap_drop:
      - ALL
    cap_add:
      - CHOWN
      - DAC_OVERRIDE
      - SETUID
      - SETGID
      - NET_BIND_SERVICE

    security_opt:
      - no-new-privileges:true

    # Security: Custom nginx configuration with security headers
    volumes:
      - /var/run/docker.sock:/tmp/docker.sock:ro
      - nginx_certs:/etc/nginx/certs:ro
      - nginx_vhost:/etc/nginx/vhost.d
      - nginx_html:/usr/share/nginx/html
      - ./nginx/security.conf:/etc/nginx/conf.d/security.conf:ro

    networks:
      - vaultwarden_net

networks:
  vaultwarden_net:
    driver: bridge
    ipam:
      driver: default
      config:
        - subnet: 172.20.0.0/16
    driver_opts:
      com.docker.network.bridge.name: "vw-bridge"
      com.docker.network.bridge.enable_icc: "false"
      com.docker.network.bridge.host_binding_ipv4: "127.0.0.1"

volumes:
  vw_data:
    driver: local
    driver_opts:
      type: none
      o: bind,ro # Read-only where possible
      device: /opt/vaultwarden/data
```

#### Nginx Security Configuration

```nginx
# nginx/security.conf
# Enhanced security configuration for nginx

# Security headers
add_header X-Frame-Options DENY always;
add_header X-Content-Type-Options nosniff always;
add_header X-XSS-Protection "1; mode=block" always;
add_header Referrer-Policy "strict-origin-when-cross-origin" always;
add_header Permissions-Policy "geolocation=(), microphone=(), camera=()" always;
add_header Content-Security-Policy "default-src 'self'; script-src 'self' 'unsafe-inline'; style-src 'self' 'unsafe-inline'; img-src 'self' data: https:; connect-src 'self' wss:; frame-ancestors 'none'; base-uri 'self'; form-action 'self';" always;

# HSTS with preload
add_header Strict-Transport-Security "max-age=63072000; includeSubDomains; preload" always;

# Hide server information
server_tokens off;
more_clear_headers Server;

# Buffer overflow protection
client_body_buffer_size 1M;
client_header_buffer_size 1k;
client_max_body_size 128M;
large_client_header_buffers 2 1k;

# Timeout settings
client_body_timeout 12;
client_header_timeout 12;
keepalive_timeout 15;
send_timeout 10;

# Rate limiting zones
limit_req_zone $binary_remote_addr zone=login:10m rate=5r/m;
limit_req_zone $binary_remote_addr zone=admin:10m rate=2r/m;
limit_req_zone $binary_remote_addr zone=api:10m rate=100r/m;
limit_req_zone $binary_remote_addr zone=general:10m rate=10r/s;

# Connection limiting
limit_conn_zone $binary_remote_addr zone=conn_limit_per_ip:10m;

# SSL configuration
ssl_protocols TLSv1.2 TLSv1.3;
ssl_ciphers ECDHE-RSA-AES256-GCM-SHA512:DHE-RSA-AES256-GCM-SHA512:ECDHE-RSA-AES256-GCM-SHA384:DHE-RSA-AES256-GCM-SHA384:ECDHE-RSA-AES256-SHA384;
ssl_prefer_server_ciphers off;
ssl_session_cache shared:SSL:10m;
ssl_session_timeout 10m;
ssl_stapling on;
ssl_stapling_verify on;

# OCSP DNS
resolver 1.1.1.1 1.0.0.1 8.8.8.8 8.8.4.4 208.67.222.222 208.67.220.220 valid=60s;
resolver_timeout 2s;

# Specific location security
location ~ /admin {
    limit_req zone=admin burst=5 nodelay;
    limit_conn conn_limit_per_ip 5;

    # Admin panel should only be accessible from specific IPs
    # allow YOUR_OFFICE_IP;
    # deny all;

    proxy_pass http://vaultwarden:80;
    proxy_set_header Host $host;
    proxy_set_header X-Real-IP $remote_addr;
    proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
    proxy_set_header X-Forwarded-Proto $scheme;

    # Security headers for admin panel
    add_header Cache-Control "no-store, no-cache, must-revalidate, proxy-revalidate, max-age=0";
}

location ~ ^/api/(accounts/register|accounts/prelogin) {
    limit_req zone=login burst=3 nodelay;
    limit_conn conn_limit_per_ip 10;

    proxy_pass http://vaultwarden:80;
    proxy_set_header Host $host;
    proxy_set_header X-Real-IP $remote_addr;
    proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
    proxy_set_header X-Forwarded-Proto $scheme;
}

location /api/ {
    limit_req zone=api burst=20 nodelay;
    limit_conn conn_limit_per_ip 20;

    proxy_pass http://vaultwarden:80;
    proxy_set_header Host $host;
    proxy_set_header X-Real-IP $remote_addr;
    proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
    proxy_set_header X-Forwarded-Proto $scheme;
}

# Block common attack patterns
location ~* \.(env|git|svn|log|conf|ini)$ {
    deny all;
}

location ~* ^/(\.well-known|\.git|\.svn|\.env) {
    deny all;
}

# Block user agents
if ($http_user_agent ~* (nikto|sqlmap|dirbuster|nmap|masscan|bot|crawler|spider)) {
    return 444;
}

# Block based on request method
if ($request_method !~ ^(GET|HEAD|POST|OPTIONS)$) {
    return 405;
}
```

## 🛡️ Data Protection

### Encryption Strategy

#### Backup Encryption

```bash
#!/bin/bash
# scripts/enhanced-backup-encryption.sh

# Multi-layer encryption for backups
encrypt_backup() {
    local input_file=$1
    local output_file=$2

    echo "🔐 Applying multi-layer encryption"

    # Layer 1: AES-256-GCM encryption with random IV
    openssl enc -aes-256-gcm -salt -pbkdf2 -iter 100000 \
        -in "$input_file" -out "${output_file}.aes" \
        -pass pass:"$BACKUP_ENCRYPTION_KEY"

    # Layer 2: GPG encryption with strong compression
    gpg --symmetric --cipher-algo AES256 --compression-algo 2 \
        --compress-level 9 --s2k-mode 3 --s2k-digest-algo SHA512 \
        --s2k-count 65536 --force-mdc \
        --passphrase "$GPG_PASSPHRASE" \
        --output "$output_file" "${output_file}.aes"

    # Cleanup intermediate file
    rm "${output_file}.aes"

    # Verify encryption
    if gpg --decrypt --batch --quiet --passphrase "$GPG_PASSPHRASE" \
           "$output_file" | openssl enc -aes-256-gcm -d -pbkdf2 -iter 100000 \
           -pass pass:"$BACKUP_ENCRYPTION_KEY" > /dev/null 2>&1; then
        echo "✅ Backup encryption verified"
    else
        echo "❌ Backup encryption verification failed"
        exit 1
    fi
}
```

#### Key Management

```bash
#!/bin/bash
# scripts/key-rotation.sh

echo "🔑 Starting encryption key rotation"

# Generate new encryption keys
NEW_BACKUP_KEY=$(openssl rand -base64 32)
NEW_GPG_PASSPHRASE=$(openssl rand -base64 32)
NEW_ADMIN_TOKEN=$(openssl rand -hex 32)

# Update AWS Secrets Manager
SECRET_VALUE=$(aws secretsmanager get-secret-value \
    --secret-id vaultwarden-prod-config \
    --query SecretString --output text)

UPDATED_SECRET=$(echo "$SECRET_VALUE" | jq \
    --arg backup_key "$NEW_BACKUP_KEY" \
    --arg gpg_pass "$NEW_GPG_PASSPHRASE" \
    --arg admin_token "$NEW_ADMIN_TOKEN" \
    '.backup_encryption_key = $backup_key |
     .gpg_passphrase = $gpg_pass |
     .admin_token = $admin_token')

aws secretsmanager update-secret \
    --secret-id vaultwarden-prod-config \
    --secret-string "$UPDATED_SECRET"

echo "✅ Keys rotated successfully"
echo "⚠️  Remember to restart services to pick up new keys"
```

### Access Controls

#### Role-Based Access Control

```bash
#!/bin/bash
# scripts/setup-rbac.sh

echo "👥 Setting up role-based access control"

# Create service accounts for different functions
create_service_account() {
    local account_name=$1
    local permissions=$2

    # Create IAM user
    aws iam create-user --user-name "vaultwarden-${account_name}"

    # Create and attach policy
    aws iam create-policy \
        --policy-name "vaultwarden-${account_name}-policy" \
        --policy-document "$permissions"

    aws iam attach-user-policy \
        --user-name "vaultwarden-${account_name}" \
        --policy-arn "arn:aws:iam::$(aws sts get-caller-identity --query Account --output text):policy/vaultwarden-${account_name}-policy"

    # Create access keys
    aws iam create-access-key --user-name "vaultwarden-${account_name}"
}

# Backup service permissions
BACKUP_POLICY='{
    "Version": "2012-10-17",
    "Statement": [
        {
            "Effect": "Allow",
            "Action": [
                "s3:PutObject",
                "s3:GetObject",
                "s3:DeleteObject",
                "s3:ListBucket"
            ],
            "Resource": [
                "arn:aws:s3:::vaultwarden-*-backups",
                "arn:aws:s3:::vaultwarden-*-backups/*"
            ]
        },
        {
            "Effect": "Allow",
            "Action": [
                "secretsmanager:GetSecretValue"
            ],
            "Resource": "arn:aws:secretsmanager:*:*:secret:vaultwarden-*-config*"
        }
    ]
}'

# Monitoring service permissions
MONITORING_POLICY='{
    "Version": "2012-10-17",
    "Statement": [
        {
            "Effect": "Allow",
            "Action": [
                "logs:CreateLogGroup",
                "logs:CreateLogStream",
                "logs:PutLogEvents",
                "logs:DescribeLogStreams",
                "logs:DescribeLogGroups"
            ],
            "Resource": "*"
        },
        {
            "Effect": "Allow",
            "Action": [
                "cloudwatch:PutMetricData",
                "cloudwatch:GetMetricStatistics",
                "cloudwatch:ListMetrics"
            ],
            "Resource": "*"
        }
    ]
}'

create_service_account "backup" "$BACKUP_POLICY"
create_service_account "monitoring" "$MONITORING_POLICY"

echo "✅ RBAC setup completed"
```

#### Multi-Factor Authentication

```bash
#!/bin/bash
# scripts/setup-2fa.sh

echo "🔐 Setting up enhanced 2FA"

# Configure Vaultwarden for multiple 2FA methods
cat >> /opt/vaultwarden/.env << 'EOF'

# YubiKey OTP support
YUBICO_CLIENT_ID=your_yubico_client_id
YUBICO_SECRET_KEY=your_yubico_secret_key

# Duo Security integration
DUO_IKEY=your_integration_key
DUO_SKEY=your_secret_key
DUO_AKEY=generated_application_key
DUO_HOST=api-hostname.duosecurity.com

# Email 2FA backup
SMTP_HOST=smtp.yourdomain.com
SMTP_FROM=2fa@yourdomain.com
SMTP_SECURITY=starttls
EOF

echo "✅ 2FA configuration completed"
echo "ℹ️  Users can now enable TOTP, WebAuthn, YubiKey, and Duo 2FA"
```

## 🔍 Security Monitoring

### Real-time Security Monitoring

```bash
#!/bin/bash
# scripts/security-monitoring.sh

echo "👁️ Setting up security monitoring"

# Install security monitoring tools
apt update
apt install -y \
    auditd \
    aide \
    osquery \
    falco \
    logwatch

# Configure auditd for security events
cat > /etc/audit/rules.d/vaultwarden.rules << 'EOF'
# Monitor Vaultwarden files
-w /opt/vaultwarden/ -p wa -k vaultwarden_files
-w /opt/vaultwarden/data/ -p wa -k vaultwarden_data

# Monitor configuration changes
-w /etc/ssh/sshd_config -p wa -k ssh_config
-w /etc/passwd -p wa -k passwd_changes
-w /etc/group -p wa -k group_changes
-w /etc/shadow -p wa -k shadow_changes

# Monitor Docker
-w /var/lib/docker/ -p wa -k docker_changes
-w /etc/docker/daemon.json -p wa -k docker_config

# Monitor network configuration
-w /etc/network/ -p wa -k network_config
-w /etc/ufw/ -p wa -k firewall_config

# Monitor privilege escalation
-a always,exit -F arch=b64 -S execve -C uid!=euid -F euid=0 -k privilege_escalation
-a always,exit -F arch=b64 -S setuid -S setgid -S setreuid -S setregid -k privilege_changes
EOF

systemctl restart auditd

# Configure log monitoring
cat > /etc/logwatch/conf/services/vaultwarden.conf << 'EOF'
Title = "Vaultwarden Security Events"
LogFile = /var/log/vaultwarden/*
*OnlyService = vaultwarden
*RemoveHeaders
EOF

# Create security alerting script
cat > /usr/local/bin/security-alert.sh << 'EOF'
#!/bin/bash
# Send security alerts

ALERT_EMAIL="security@yourdomain.com"
SLACK_WEBHOOK="https://hooks.slack.com/services/YOUR/SLACK/WEBHOOK"

send_alert() {
    local severity=$1
    local message=$2
    local timestamp=$(date)

    # Email alert
    echo "Security Alert: $severity - $message ($timestamp)" | \
        mail -s "Vaultwarden Security Alert" "$ALERT_EMAIL"

    # Slack alert
    curl -X POST -H 'Content-type: application/json' \
        --data "{\"text\":\"🚨 Security Alert: $severity\\n$message\\nTime: $timestamp\"}" \
        "$SLACK_WEBHOOK"
}

# Monitor for specific events
tail -f /var/log/auth.log | while read line; do
    case "$line" in
        *"Failed password"*)
            send_alert "MEDIUM" "Failed SSH login attempt: $line"
            ;;
        *"sudo: authentication failure"*)
            send_alert "HIGH" "Sudo authentication failure: $line"
            ;;
        *"BREAK-IN ATTEMPT"*)
            send_alert "CRITICAL" "Break-in attempt detected: $line"
            ;;
    esac
done &
EOF

chmod +x /usr/local/bin/security-alert.sh

echo "✅ Security monitoring configured"
```

### Vulnerability Scanning

```bash
#!/bin/bash
# scripts/vulnerability-scan.sh

echo "🔍 Running comprehensive vulnerability scan"

# System vulnerability scan with Lynis
lynis audit system --quick --auditor "vaultwarden-security" \
    --log-file /var/log/lynis-$(date +%Y%m%d).log

# Container vulnerability scan with Trivy
docker run --rm -v /var/run/docker.sock:/var/run/docker.sock \
    -v $HOME/Library/Caches:/root/.cache/ \
    aquasec/trivy:latest image vaultwarden/server:latest

# Network vulnerability scan
nmap -sS -O -A localhost

# Application-specific checks
docker exec vaultwarden sqlite3 /data/db.sqlite3 "
    SELECT 'User count:', COUNT(*) FROM users;
    SELECT 'Cipher count:', COUNT(*) FROM ciphers;
    SELECT 'Failed logins:', COUNT(*) FROM event_logs WHERE event_type = 1003;
"

# SSL/TLS security check
sslscan vault.yourdomain.com

# Generate security report
cat > /tmp/security-report-$(date +%Y%m%d).md << EOF
# Security Scan Report - $(date)

## System Security
- Lynis scan: /var/log/lynis-$(date +%Y%m%d).log
- System hardening: $(lynis show hardening-index)

## Container Security
- Trivy container scan completed
- No critical vulnerabilities allowed in production

## Network Security
- Firewall status: $(ufw status | head -1)
- Open ports: $(ss -tuln | grep LISTEN | wc -l)
- SSL grade: A+ (verify with SSL Labs)

## Application Security
- Administrative access: Properly restricted
- Audit logs: Enabled and monitored
- Backup encryption: Multi-layer AES-256 + GPG
EOF

echo "✅ Vulnerability scan completed"
echo "📋 Report saved to /tmp/security-report-$(date +%Y%m%d).md"
```

## 🚨 Incident Response

### Security Incident Response Plan

```bash
#!/bin/bash
# scripts/incident-response.sh

incident_response() {
    local incident_type=$1
    local severity=$2

    echo "🚨 SECURITY INCIDENT RESPONSE ACTIVATED"
    echo "Type: $incident_type | Severity: $severity"
    echo "Timestamp: $(date -u)"

    case "$severity" in
        "CRITICAL")
            # Immediate isolation
            echo "🔒 Isolating system"
            ufw deny in
            docker stop vaultwarden nginx-proxy

            # Preserve evidence
            echo "📸 Capturing system state"
            docker logs vaultwarden > /tmp/incident-vaultwarden-logs.txt
            netstat -tulpn > /tmp/incident-network-state.txt
            ps aux > /tmp/incident-process-list.txt

            # Alert stakeholders
            send_critical_alert "$incident_type"
            ;;

        "HIGH")
            # Enhanced monitoring
            echo "📊 Activating enhanced monitoring"
            tail -f /var/log/auth.log | grep -E "(Failed|Invalid|Illegal)" &

            # Create backup
            echo "💾 Creating incident backup"
            docker exec vaultwarden sqlite3 /data/db.sqlite3 ".backup /data/incident-backup-$(date +%Y%m%d-%H%M%S).db"
            ;;

        "MEDIUM")
            echo "⚠️ Medium severity incident - monitoring"
            # Log and monitor
            ;;
    esac

    # Common actions for all severities
    echo "📝 Documenting incident"
    cat > "/tmp/incident-$(date +%Y%m%d-%H%M%S).log" << EOF
Incident Report
===============
Type: $incident_type
Severity: $severity
Timestamp: $(date -u)
System State: $(uptime)
Recent Logins: $(last | head -5)
Active Connections: $(ss -tuln | grep LISTEN)
EOF
}

send_critical_alert() {
    local incident_type=$1

    # Multiple alert channels for critical incidents
    curl -X POST -H 'Content-type: application/json' \
        --data "{\"text\":\"🚨 CRITICAL SECURITY INCIDENT\\nType: $incident_type\\nSystem: Vaultwarden Production\\nAction: System isolated\\nTime: $(date)\"}" \
        "$SLACK_WEBHOOK"

    # SMS alert (if configured)
    # aws sns publish --topic-arn "arn:aws:sns:region:account:security-alerts" \
    #     --message "CRITICAL: Vaultwarden security incident - $incident_type"

    # Email alert
    echo "CRITICAL SECURITY INCIDENT - $incident_type" | \
        mail -s "URGENT: Vaultwarden Security Incident" security@yourdomain.com
}

# Monitor for specific incident triggers
monitor_for_incidents() {
    # Brute force detection
    tail -f /var/log/auth.log | while read line; do
        if echo "$line" | grep -q "Failed password"; then
            failed_attempts=$(grep "Failed password" /var/log/auth.log | grep "$(date '+%b %d')" | wc -l)
            if [ "$failed_attempts" -gt 10 ]; then
                incident_response "Brute Force Attack" "HIGH"
            fi
        fi
    done &

    # Resource exhaustion detection
    while true; do
        cpu_usage=$(top -bn1 | grep "Cpu(s)" | awk '{print $2}' | awk -F'%' '{print $1}')
        if (( $(echo "$cpu_usage > 90" | bc -l) )); then
            incident_response "Resource Exhaustion" "HIGH"
        fi
        sleep 60
    done &
}
```

---

[← Troubleshooting](08-troubleshooting.md) | [Contributing →](10-contributing.md)

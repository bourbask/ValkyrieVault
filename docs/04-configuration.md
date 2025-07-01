# 🔧 Configuration Guide

This document provides comprehensive configuration options for ValkyrieVault, covering application settings, environment variables, security options, and advanced customization.

## 🏗️ Infrastructure Configuration

### OpenTofu/Terraform Variables

#### Core Variables

```hcl
# terraform/environments/production/terraform.tfvars

# Basic Configuration
aws_region   = "eu-west-3"        # AWS region for resources
environment  = "prod"             # Environment name (dev/staging/prod)
project_name = "vaultwarden"      # Project identifier

# Domain Configuration
domain           = "vault.yourdomain.com"
admin_email      = "admin@yourdomain.com"
lets_encrypt_env = "production"   # or "staging" for testing

# VPS Configuration
vps_ip          = "YOUR_VPS_IP"
vps_hostname    = "vault-prod"
ssh_public_key  = "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAA..."

# Resource Sizing
instance_type = "t3.small"        # AWS instance type equivalent
cpu_limit     = "1000m"          # CPU limit in millicores
memory_limit  = "512Mi"          # Memory limit

# Backup Configuration
backup_retention_days = {
  hourly  = 2    # 48 hours (2 days * 24 hours)
  daily   = 30   # 30 days
  monthly = 12   # 12 months
  yearly  = 5    # 5 years
}

# Feature Flags
enable_monitoring          = true
enable_multi_region_backup = true
enable_advanced_logging    = true
enable_metrics_collection  = true

# Storage Configuration
database_storage_gb = 10
backup_storage_gb   = 100
log_retention_days  = 30
```

#### Advanced Variables

```hcl
# Advanced S3 Configuration
s3_config = {
  bucket_prefix           = "vaultwarden"
  force_destroy           = false
  versioning_enabled      = true
  mfa_delete_enabled      = false
  lifecycle_rules_enabled = true

  # Storage classes for cost optimization
  transition_to_ia_days        = 30
  transition_to_glacier_days   = 90
  transition_to_deep_archive_days = 365
}

# Network Configuration
network_config = {
  allowed_ips = [
    "0.0.0.0/0"      # Allow all (modify for security)
  ]

  blocked_countries = [
    # "CN",          # China
    # "RU",          # Russia
    # "IR",          # Iran
  ]

  rate_limiting = {
    enabled = true
    requests_per_minute = 60
    requests_per_hour = 1000
  }
}

# Monitoring Configuration
monitoring_config = {
  prometheus_retention = "30d"
  grafana_admin_password = "CHANGE_ME"
  alertmanager_webhook = "https://hooks.slack.com/services/..."

  alert_thresholds = {
    cpu_usage_percent    = 80
    memory_usage_percent = 85
    disk_usage_percent   = 90
    backup_failure_hours = 4
  }
}
```

### Environment-Specific Configurations

#### Development Environment

```hcl
# terraform/environments/development/terraform.tfvars
aws_region   = "eu-west-3"
environment  = "dev"
project_name = "vaultwarden"
domain       = "dev-vault.yourdomain.com"

# Reduced resources for development
backup_retention_days = {
  hourly  = 1    # 24 hours only
  daily   = 7    # 1 week
  monthly = 3    # 3 months
  yearly  = 1    # 1 year
}

# Development-specific settings
instance_type = "t3.micro"
cpu_limit     = "500m"
memory_limit  = "256Mi"

enable_monitoring          = false  # Disable to save costs
enable_multi_region_backup = false
enable_advanced_logging    = false

# Less strict security for development
network_config = {
  allowed_ips = ["0.0.0.0/0"]
  blocked_countries = []
  rate_limiting = {
    enabled = false
    requests_per_minute = 1000
    requests_per_hour = 10000
  }
}
```

#### Staging Environment

```hcl
# terraform/environments/staging/terraform.tfvars
aws_region   = "eu-west-3"
environment  = "staging"
project_name = "vaultwarden"
domain       = "staging-vault.yourdomain.com"

# Production-like but reduced retention
backup_retention_days = {
  hourly  = 1    # 24 hours
  daily   = 14   # 2 weeks
  monthly = 6    # 6 months
  yearly  = 2    # 2 years
}

# Medium resources
instance_type = "t3.small"
cpu_limit     = "750m"
memory_limit  = "384Mi"

enable_monitoring          = true
enable_multi_region_backup = false  # Single region for staging
enable_advanced_logging    = true
```

## 🐳 Application Configuration

### Vaultwarden Environment Variables

#### Core Application Settings

```bash
# Docker environment variables
# Note: These are managed by Terraform and stored in AWS Secrets Manager

# Basic Configuration
DOMAIN=https://vault.yourdomain.com
ADMIN_TOKEN=<generated-secure-token>
DATABASE_URL=sqlite:///data/db.sqlite3

# Feature toggles
WEBSOCKET_ENABLED=true
SENDS_ALLOWED=true
EMERGENCY_ACCESS_ALLOWED=true
EMAIL_CHANGE_ALLOWED=true
PASSWORD_HINTS_ALLOWED=false

# Organization settings
ORG_CREATION_USERS=all          # all, none, or email list
ORG_EVENTS_ENABLED=true
ORG_GROUPS_ENABLED=true

# Security settings
SIGNUPS_ALLOWED=false           # Disable after initial setup
SIGNUPS_VERIFY=false
SIGNUPS_DOMAINS_WHITELIST=""    # Comma-separated list
INVITATIONS_ALLOWED=true
PASSWORD_ITERATIONS=100000

# Session settings
EXTENDED_LOGGING=true
LOG_LEVEL=info                  # trace, debug, info, warn, error
LOG_FILE=/data/vaultwarden.log
```

#### Advanced Security Configuration

```bash
# Two-Factor Authentication
YUBICO_CLIENT_ID=your_client_id
YUBICO_SECRET_KEY=your_secret_key

# Have I Been Pwned integration
HIBP_API_KEY=your_hibp_api_key

# Duo Security integration
DUO_IKEY=your_integration_key
DUO_SKEY=your_secret_key
DUO_AKEY=your_application_key
DUO_HOST=api-hostname.duosecurity.com

# Email configuration
SMTP_HOST=smtp.yourdomain.com
SMTP_FROM=noreply@yourdomain.com
SMTP_FROM_NAME="Vaultwarden Server"
SMTP_PORT=587
SMTP_SECURITY=starttls          # starttls, force_tls, or off
SMTP_USERNAME=smtp_user
SMTP_PASSWORD=smtp_password

# Rate limiting
ADMIN_RATELIMIT_SECONDS=300     # Admin panel rate limit
ADMIN_RATELIMIT_MAX_BURST=3     # Admin panel burst limit
```

#### Performance and Storage Settings

```bash
# Database configuration
DATABASE_MAX_CONNS=10
DATABASE_TIMEOUT=30

# File upload limits
ROCKET_LIMITS='{json=10485760,data-form=10485760,file=10485760}'

# Icon service
ICON_CACHE_TTL=2592000          # 30 days
ICON_CACHE_NEGTTL=259200        # 3 days
DISABLE_ICON_DOWNLOAD=false
ICON_DOWNLOAD_TIMEOUT=10

# Attachment storage
ATTACHMENTS_FOLDER=data/attachments
```

### Docker Compose Configuration

#### Production Docker Compose

```yaml
# docker/docker-compose.prod.yml
version: "3.8"

services:
  vaultwarden:
    image: vaultwarden/server:1.30.1
    container_name: vaultwarden
    restart: unless-stopped

    environment:
      - DOMAIN=${DOMAIN}
      - ADMIN_TOKEN=${ADMIN_TOKEN}
      - DATABASE_URL=${DATABASE_URL}
      - WEBSOCKET_ENABLED=${WEBSOCKET_ENABLED:-true}
      - SENDS_ALLOWED=${SENDS_ALLOWED:-true}
      - SIGNUPS_ALLOWED=${SIGNUPS_ALLOWED:-false}
      - LOG_LEVEL=${LOG_LEVEL:-info}
      - EXTENDED_LOGGING=${EXTENDED_LOGGING:-true}

    volumes:
      - vw_data:/data

    networks:
      - vaultwarden_net

    ports:
      - "8080:80"

    healthcheck:
      test: ["CMD", "curl", "-f", "http://localhost:80/alive"]
      interval: 30s
      timeout: 10s
      retries: 3
      start_period: 40s

    deploy:
      resources:
        limits:
          memory: 512M
          cpus: "1.0"
        reservations:
          memory: 256M
          cpus: "0.5"

    labels:
      - "com.centurylinklabs.watchtower.enable=true"
      - "backup.enable=true"

  nginx-proxy:
    image: nginxproxy/nginx-proxy:1.4
    container_name: nginx-proxy
    restart: unless-stopped

    environment:
      - ENABLE_IPV6=true
      - TRUST_DOWNSTREAM_PROXY=false

    ports:
      - "80:80"
      - "443:443"

    volumes:
      - /var/run/docker.sock:/tmp/docker.sock:ro
      - nginx_certs:/etc/nginx/certs:ro
      - nginx_vhost:/etc/nginx/vhost.d
      - nginx_html:/usr/share/nginx/html
      - ./nginx/custom.conf:/etc/nginx/conf.d/custom.conf:ro

    networks:
      - vaultwarden_net

    depends_on:
      - vaultwarden

  letsencrypt:
    image: nginxproxy/acme-companion:2.2
    container_name: nginx-proxy-letsencrypt
    restart: unless-stopped

    environment:
      - NGINX_PROXY_CONTAINER=nginx-proxy
      - ACME_CA_URI=${LETS_ENCRYPT_URI:-https://acme-v02.api.letsencrypt.org/directory}
      - DEFAULT_EMAIL=${ADMIN_EMAIL}

    volumes:
      - /var/run/docker.sock:/var/run/docker.sock:ro
      - nginx_certs:/etc/nginx/certs
      - nginx_vhost:/etc/nginx/vhost.d
      - nginx_html:/usr/share/nginx/html
      - acme_data:/etc/acme.sh

    networks:
      - vaultwarden_net

    depends_on:
      - nginx-proxy

  backup-service:
    build:
      context: .
      dockerfile: Dockerfile.backup
    container_name: vw_backup
    restart: unless-stopped

    environment:
      - S3_ENDPOINT=${S3_ENDPOINT}
      - S3_BUCKET=${S3_BUCKET}
      - S3_REGION=${S3_REGION}
      - S3_ACCESS_KEY=${S3_ACCESS_KEY}
      - S3_SECRET_KEY=${S3_SECRET_KEY}
      - BACKUP_ENCRYPTION_KEY=${BACKUP_ENCRYPTION_KEY}
      - ENVIRONMENT=${ENVIRONMENT}

    volumes:
      - vw_data:/source:ro
      - backup_data:/backup
      - /var/log/backup:/var/log

    networks:
      - vaultwarden_net

    depends_on:
      vaultwarden:
        condition: service_healthy

    command: >
      sh -c "
        crond -f &
        while true; do
          sleep 300
          if ! pgrep crond > /dev/null; then
            echo 'Cron died, restarting...'
            crond -f &
          fi
        done
      "

networks:
  vaultwarden_net:
    driver: bridge
    ipam:
      driver: default
      config:
        - subnet: 172.20.0.0/16

volumes:
  vw_data:
    driver: local
    driver_opts:
      type: none
      o: bind
      device: /opt/vaultwarden/data

  nginx_certs:
    driver: local

  nginx_vhost:
    driver: local

  nginx_html:
    driver: local

  acme_data:
    driver: local

  backup_data:
    driver: local
```

#### Development Docker Compose

```yaml
# docker/docker-compose.dev.yml
version: "3.8"

services:
  vaultwarden:
    extends:
      file: docker-compose.prod.yml
      service: vaultwarden

    environment:
      - DOMAIN=https://dev-vault.yourdomain.com
      - LOG_LEVEL=debug
      - SIGNUPS_ALLOWED=true # Allow signups in dev
      - ADMIN_TOKEN=dev-admin-token-change-me

    ports:
      - "8081:80" # Different port for dev

    volumes:
      - ./dev-data:/data # Local directory for dev data

  # Skip nginx-proxy and letsencrypt for local development
  # Access directly via localhost:8081

volumes:
  dev_data:
    driver: local
```

## 🔐 Security Configuration

### SSL/TLS Configuration

#### Custom Nginx Configuration

```nginx
# nginx/custom.conf
# Custom nginx configuration for enhanced security

# Security headers
add_header X-Frame-Options DENY always;
add_header X-Content-Type-Options nosniff always;
add_header X-XSS-Protection "1; mode=block" always;
add_header Referrer-Policy "strict-origin-when-cross-origin" always;
add_header Content-Security-Policy "default-src 'self'; script-src 'self' 'unsafe-inline'; style-src 'self' 'unsafe-inline'; img-src 'self' data: https:; connect-src 'self' wss:; frame-ancestors 'none';" always;

# HSTS (HTTP Strict Transport Security)
add_header Strict-Transport-Security "max-age=31536000; includeSubDomains; preload" always;

# Hide nginx version
server_tokens off;

# Client upload size
client_max_body_size 128M;

# Timeout settings
client_body_timeout 12;
client_header_timeout 12;
keepalive_timeout 15;
send_timeout 10;

# Gzip compression
gzip on;
gzip_comp_level 6;
gzip_min_length 1000;
gzip_proxied any;
gzip_types
    application/atom+xml
    application/geo+json
    application/javascript
    application/x-javascript
    application/json
    application/ld+json
    application/manifest+json
    application/rdf+xml
    application/rss+xml
    application/xhtml+xml
    application/xml
    font/eot
    font/otf
    font/ttf
    image/svg+xml
    text/css
    text/javascript
    text/plain
    text/xml;

# Rate limiting
limit_req_zone $binary_remote_addr zone=login:10m rate=10r/m;
limit_req_zone $binary_remote_addr zone=admin:10m rate=5r/m;

# Specific location blocks for Vaultwarden
location /admin {
    limit_req zone=admin burst=3 nodelay;
    proxy_pass http://vaultwarden:80;
    proxy_set_header Host $host;
    proxy_set_header X-Real-IP $remote_addr;
    proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
    proxy_set_header X-Forwarded-Proto $scheme;
}

location /api/accounts/register {
    limit_req zone=login burst=2 nodelay;
    proxy_pass http://vaultwarden:80;
    proxy_set_header Host $host;
    proxy_set_header X-Real-IP $remote_addr;
    proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
    proxy_set_header X-Forwarded-Proto $scheme;
}

location /api/accounts/prelogin {
    limit_req zone=login burst=5 nodelay;
    proxy_pass http://vaultwarden:80;
    proxy_set_header Host $host;
    proxy_set_header X-Real-IP $remote_addr;
    proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
    proxy_set_header X-Forwarded-Proto $scheme;
}

# WebSocket support
location /notifications/hub {
    proxy_pass http://vaultwarden:3012;
    proxy_http_version 1.1;
    proxy_set_header Upgrade $http_upgrade;
    proxy_set_header Connection "upgrade";
    proxy_set_header Host $host;
    proxy_set_header X-Real-IP $remote_addr;
    proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
    proxy_set_header X-Forwarded-Proto $scheme;
}
```

### Firewall Configuration

#### UFW (Uncomplicated Firewall) Setup

```bash
#!/bin/bash
# scripts/configure-firewall.sh

# Reset UFW to default state
ufw --force reset

# Default policies
ufw default deny incoming
ufw default allow outgoing

# SSH access (change port if using non-standard)
ufw allow 22/tcp comment 'SSH'

# HTTP and HTTPS
ufw allow 80/tcp comment 'HTTP'
ufw allow 443/tcp comment 'HTTPS'

# Deny specific ports that should never be exposed
ufw deny 8080/tcp comment 'Internal Vaultwarden port'
ufw deny 3012/tcp comment 'Vaultwarden WebSocket port'

# Optional: Allow from specific IP ranges only
# ufw allow from YOUR_OFFICE_IP to any port 22
# ufw allow from MONITORING_SERVER_IP to any port 9090

# Rate limiting for SSH brute force protection
ufw limit ssh

# Enable UFW
ufw --force enable

# Show status
ufw status verbose
```

#### iptables Rules (Advanced)

```bash
#!/bin/bash
# scripts/configure-iptables.sh

# Flush existing rules
iptables -F
iptables -X
iptables -Z

# Default policies
iptables -P INPUT DROP
iptables -P FORWARD DROP
iptables -P OUTPUT ACCEPT

# Allow loopback traffic
iptables -A INPUT -i lo -j ACCEPT
iptables -A OUTPUT -o lo -j ACCEPT

# Allow established and related connections
iptables -A INPUT -m conntrack --ctstate ESTABLISHED,RELATED -j ACCEPT

# SSH with rate limiting
iptables -A INPUT -p tcp --dport 22 -m conntrack --ctstate NEW -m limit --limit 3/min --limit-burst 3 -j ACCEPT

# HTTP and HTTPS
iptables -A INPUT -p tcp --dport 80 -j ACCEPT
iptables -A INPUT -p tcp --dport 443 -j ACCEPT

# Drop invalid packets
iptables -A INPUT -m conntrack --ctstate INVALID -j DROP

# Log dropped packets (optional)
iptables -A INPUT -j LOG --log-prefix "iptables-dropped: " --log-level 7

# Save rules (varies by distribution)
# Ubuntu/Debian:
iptables-save > /etc/iptables/rules.v4
# CentOS/RHEL:
# iptables-save > /etc/sysconfig/iptables
```

## 📊 Monitoring Configuration

### Prometheus Configuration

```yaml
# monitoring/prometheus.yml
global:
  scrape_interval: 15s
  evaluation_interval: 15s

rule_files:
  - "/etc/prometheus/rules/*.yml"

alerting:
  alertmanagers:
    - static_configs:
        - targets:
            - alertmanager:9093

scrape_configs:
  - job_name: "prometheus"
    static_configs:
      - targets: ["localhost:9090"]

  - job_name: "vaultwarden"
    static_configs:
      - targets: ["vaultwarden:80"]
    metrics_path: "/metrics"
    scrape_interval: 30s

  - job_name: "node_exporter"
    static_configs:
      - targets: ["node_exporter:9100"]

  - job_name: "backup_metrics"
    static_configs:
      - targets: ["backup-service:8080"]
    scrape_interval: 60s
```

### Grafana Dashboard Configuration

```json
{
  "dashboard": {
    "id": null,
    "title": "ValkyrieVault",
    "panels": [
      {
        "title": "User Activity",
        "type": "stat",
        "targets": [
          {
            "expr": "vw_users_total",
            "legendFormat": "Total Users"
          }
        ]
      },
      {
        "title": "System Resources",
        "type": "graph",
        "targets": [
          {
            "expr": "100 - (node_memory_MemAvailable_bytes / node_memory_MemTotal_bytes * 100)",
            "legendFormat": "Memory Usage %"
          },
          {
            "expr": "100 - (rate(node_cpu_seconds_total{mode=\"idle\"}[5m]) * 100)",
            "legendFormat": "CPU Usage %"
          }
        ]
      }
    ]
  }
}
```

---

[← Installation](03-installation.md) | [Deployment →](05-deployment.md)

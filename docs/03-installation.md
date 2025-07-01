# ⚙️ Installation Guide

This comprehensive guide walks you through installing ValkyrieVault from scratch, covering all prerequisites, setup steps, and configuration details.

## 📋 Prerequisites

### System Requirements

#### Minimum Requirements

- **VPS/Server**: 1GB RAM, 1 CPU core, 10GB storage
- **Operating System**: Ubuntu 20.04 LTS or later (recommended)
- **Network**: Static IP address, internet connectivity
- **Domain**: Registered domain with DNS control

#### Recommended Requirements

- **VPS/Server**: 2GB RAM, 2 CPU cores, 25GB SSD storage
- **Operating System**: Ubuntu 22.04 LTS
- **Network**: Dedicated IP, CDN integration
- **Domain**: Primary domain + subdomain for staging

#### Production Requirements

- **VPS/Server**: 4GB RAM, 2+ CPU cores, 50GB SSD storage
- **Backup Strategy**: Multi-region backup storage
- **Monitoring**: Dedicated monitoring stack
- **Security**: SSL certificates, firewall configuration

### Required Accounts & Services

#### Essential Services

- [ ] **AWS Account** with billing enabled
- [ ] **VPS Provider** (OVH, DigitalOcean, AWS EC2, etc.)
- [ ] **Domain Registrar** (Cloudflare, Namecheap, etc.)
- [ ] **GitHub Account** for repository hosting

#### Optional Services

- [ ] **Cloudflare** for CDN and DNS management
- [ ] **Backblaze B2** for secondary backup storage
- [ ] **PagerDuty** for advanced alerting
- [ ] **Grafana Cloud** for managed monitoring

### Local Development Tools

```bash
# Install required tools on macOS
brew install opentofu terraform awscli ansible git docker

# Install on Ubuntu/Debian
sudo apt update
sudo apt install -y software-properties-common gnupg2 curl

# OpenTofu
curl -fsSL https://get.opentofu.org/install.sh | sudo bash

# AWS CLI
curl "https://awscli.amazonaws.com/awscli-exe-linux-x86_64.zip" -o "awscliv2.zip"
unzip awscliv2.zip && sudo ./aws/install

# Ansible
sudo apt-add-repository --yes --update ppa:ansible/ansible
sudo apt install -y ansible

# Docker
curl -fsSL https://get.docker.com -o get-docker.sh
sudo sh get-docker.sh
sudo usermod -aG docker $USER
```

## 🏗️ Infrastructure Setup

### Step 1: AWS Account Configuration

#### Create AWS Account

1. Sign up at [aws.amazon.com](https://aws.amazon.com)
2. Complete billing setup
3. Enable MFA for root account
4. Create IAM user for Terraform

#### Configure AWS CLI

```bash
# Configure AWS credentials
aws configure
# AWS Access Key ID: [Your Access Key]
# AWS Secret Access Key: [Your Secret Key]
# Default region name: eu-west-3
# Default output format: json

# Verify configuration
aws sts get-caller-identity
```

#### Create S3 Backend Bucket

```bash
# Create bucket for Terraform state (replace with unique name)
aws s3 mb s3://your-unique-terraform-state-bucket

# Enable versioning
aws s3api put-bucket-versioning \
  --bucket your-unique-terraform-state-bucket \
  --versioning-configuration Status=Enabled

# Optional: Create DynamoDB table for state locking
aws dynamodb create-table \
  --table-name terraform-state-lock \
  --attribute-definitions AttributeName=LockID,AttributeType=S \
  --key-schema AttributeName=LockID,KeyType=HASH \
  --provisioned-throughput ReadCapacityUnits=5,WriteCapacityUnits=5
```

### Step 2: VPS Provisioning

#### Option A: OVH VPS Setup

```bash
# 1. Purchase VPS from OVH
# - Choose Ubuntu 22.04 LTS
# - Minimum VPS Essential (2GB RAM recommended)
# - Enable automated backup (optional)

# 2. Initial VPS configuration
ssh root@YOUR_VPS_IP

# Update system
apt update && apt upgrade -y

# Create non-root user (optional but recommended)
adduser vwalladmin
usermod -aG sudo vwalladmin
```

#### Option B: DigitalOcean Droplet

```bash
# 1. Create droplet via web interface or API
doctl compute droplet create vaultwarden-prod \
  --size s-2vcpu-2gb \
  --image ubuntu-22-04-x64 \
  --region fra1 \
  --ssh-keys YOUR_SSH_KEY_ID

# 2. Configure firewall
doctl compute firewall create vw-firewall \
  --inbound-rules "protocol:tcp,ports:22,source_addresses:0.0.0.0/0,source_addresses:::/0 protocol:tcp,ports:80,source_addresses:0.0.0.0/0 protocol:tcp,ports:443,source_addresses:0.0.0.0/0" \
  --outbound-rules "protocol:tcp,ports:all,destination_addresses:0.0.0.0/0 protocol:udp,ports:all,destination_addresses:0.0.0.0/0"
```

#### Option C: AWS EC2 Instance

```bash
# Create EC2 instance with Terraform
cat > ec2-instance.tf << EOF
resource "aws_instance" "vaultwarden" {
  ami           = "ami-0c6ebbd55ab05f070"  # Ubuntu 22.04 LTS
  instance_type = "t3.small"
  key_name      = "your-key-pair"

  vpc_security_group_ids = [aws_security_group.vaultwarden.id]

  tags = {
    Name = "vaultwarden-production"
  }
}

resource "aws_security_group" "vaultwarden" {
  name_prefix = "vaultwarden-"

  ingress {
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
    from_port   = 443
    to_port     = 443
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
}
EOF

terraform init && terraform apply
```

### Step 3: Domain Configuration

#### DNS Setup

```bash
# Configure DNS records (example with Cloudflare)
# A records
vault.yourdomain.com      IN A     YOUR_VPS_IP
staging-vault.yourdomain.com IN A  YOUR_VPS_IP
dev-vault.yourdomain.com  IN A     YOUR_VPS_IP

# CNAME records (optional)
www-vault.yourdomain.com  IN CNAME vault.yourdomain.com
```

#### Cloudflare Configuration (Optional)

```bash
# Install Cloudflare CLI
curl -L --output cloudflared.deb https://github.com/cloudflare/cloudflared/releases/latest/download/cloudflared-linux-amd64.deb
sudo dpkg -i cloudflared.deb

# Configure DNS via API
curl -X POST "https://api.cloudflare.com/client/v4/zones/YOUR_ZONE_ID/dns_records" \
     -H "Authorization: Bearer YOUR_API_TOKEN" \
     -H "Content-Type: application/json" \
     --data '{
       "type": "A",
       "name": "vault",
       "content": "YOUR_VPS_IP",
       "ttl": 1
     }'
```

## 🔧 Repository Setup

### Step 1: Clone and Configure Repository

```bash
# Clone the repository
git clone https://github.com/yourusername/vaultwarden-infra.git
cd vaultwarden-infra

# Create your configuration branch
git checkout -b setup/initial-configuration

# Copy example configurations
cp terraform/environments/production/terraform.tfvars.example \
   terraform/environments/production/terraform.tfvars

cp terraform/environments/staging/terraform.tfvars.example \
   terraform/environments/staging/terraform.tfvars

cp terraform/environments/development/terraform.tfvars.example \
   terraform/environments/development/terraform.tfvars
```

### Step 2: Configure Environment Variables

#### Production Configuration

```hcl
# terraform/environments/production/terraform.tfvars
aws_region   = "eu-west-3"
environment  = "prod"
project_name = "vaultwarden"

# Domain configuration
domain = "vault.yourdomain.com"

# Backup configuration
backup_retention_days = {
  hourly  = 2    # 48 hours
  daily   = 30   # 30 days
  monthly = 12   # 12 months
  yearly  = 5    # 5 years
}

# Resource configuration
enable_monitoring = true
enable_multi_region_backup = true
instance_type = "t3.small"

# VPS configuration
vps_ip = "YOUR_VPS_IP"
```

#### Update Backend Configuration

```hcl
# terraform/environments/production/backend.tf
terraform {
  backend "s3" {
    bucket = "your-unique-terraform-state-bucket"
    key    = "vaultwarden/prod/terraform.tfstate"
    region = "eu-west-3"

    dynamodb_table = "terraform-state-lock"
    encrypt        = true
  }
}
```

### Step 3: SSH Key Configuration

```bash
# Generate SSH key for VPS access (if not exists)
ssh-keygen -t ed25519 -f ~/.ssh/vaultwarden_rsa -C "vaultwarden@yourdomain.com"

# Add public key to VPS
ssh-copy-id -i ~/.ssh/vaultwarden_rsa.pub root@YOUR_VPS_IP

# Test connection
ssh -i ~/.ssh/vaultwarden_rsa root@YOUR_VPS_IP
```

## 🚀 Deployment Process

### Step 1: Infrastructure Deployment

#### Initialize Terraform

```bash
cd terraform/environments/production

# Initialize
tofu init

# Validate configuration
tofu validate

# Plan deployment
tofu plan -out=tfplan

# Review plan carefully
tofu show tfplan
```

#### Deploy Infrastructure

```bash
# Apply infrastructure
tofu apply tfplan

# Save outputs for later use
tofu output -json > ../../../infrastructure-outputs.json
```

### Step 2: VPS Configuration with Ansible

#### Prepare Ansible Inventory

```ini
# ansible/inventory/production
[vaultwarden_servers]
vault-prod ansible_host=YOUR_VPS_IP ansible_user=root ansible_ssh_private_key_file=~/.ssh/vaultwarden_rsa

[all:vars]
ansible_ssh_common_args='-o StrictHostKeyChecking=no'
```

#### Run Ansible Playbook

```bash
cd ansible

# Test connectivity
ansible -i inventory/production all -m ping

# Run VPS setup playbook
ansible-playbook -i inventory/production playbooks/setup-vps.yml

# Deploy application
ansible-playbook -i inventory/production playbooks/deploy-vaultwarden.yml
```

### Step 3: Application Configuration

#### Configure GitHub Secrets

Navigate to your GitHub repository → Settings → Secrets and variables → Actions:

```bash
# Production environment secrets
AWS_ACCESS_KEY_ID=AKIAIOSFODNN7EXAMPLE
AWS_SECRET_ACCESS_KEY=wJalrXUtnFEMI/K7MDENG/bPxRfiCYEXAMPLEKEY
VPS_HOST_PROD=YOUR_VPS_IP
VPS_USER=root
VPS_SSH_KEY=[Contents of ~/.ssh/vaultwarden_rsa]
DOMAIN_PROD=https://vault.yourdomain.com
```

#### Trigger Initial Deployment

```bash
# Commit and push configuration
git add .
git commit -m "feat: initial production configuration"
git push origin setup/initial-configuration

# Create pull request to main
gh pr create --title "Initial Production Setup" \
  --body "Initial configuration for production deployment" \
  --base main --head setup/initial-configuration

# Merge and trigger deployment
gh pr merge --merge
```

## ✅ Verification & Testing

### Step 1: Infrastructure Verification

```bash
# Verify AWS resources
aws s3 ls | grep vaultwarden
aws secretsmanager list-secrets | grep vaultwarden

# Check infrastructure outputs
tofu output
```

### Step 2: Application Health Checks

```bash
# Basic connectivity test
curl -I https://vault.yourdomain.com

# Health endpoint
curl https://vault.yourdomain.com/alive

# WebSocket test
curl -H "Connection: Upgrade" \
     -H "Upgrade: websocket" \
     -H "Sec-WebSocket-Version: 13" \
     -H "Sec-WebSocket-Key: test" \
     https://vault.yourdomain.com/notifications/hub
```

### Step 3: Backup Verification

```bash
# SSH to VPS and check backup service
ssh root@YOUR_VPS_IP

# Check backup container
docker logs vw_backup

# Manual backup test
docker exec vw_backup /scripts/backup-hourly.sh

# Verify S3 backup
aws s3 ls s3://vaultwarden-prod-backups-XXXXX/hourly/
```

### Step 4: Security Verification

```bash
# SSL certificate check
echo | openssl s_client -connect vault.yourdomain.com:443 | openssl x509 -noout -dates

# Port scan (should show only 80, 443, 22)
nmap -p- YOUR_VPS_IP

# Security headers check
curl -I https://vault.yourdomain.com | grep -i security
```

## 🔧 Initial Configuration

### Step 1: Admin Panel Setup

1. **Retrieve admin token**:

   ```bash
   aws secretsmanager get-secret-value \
     --secret-id vaultwarden-prod-config \
     --query SecretString --output text | jq -r .admin_token
   ```

2. **Access admin panel**: Visit `https://vault.yourdomain.com/admin`
3. **Configure settings**:
   - Disable user registration (if desired)
   - Configure SMTP settings
   - Set organization policies
   - Enable/disable features

### Step 2: First User Registration

1. **Open Vaultwarden**: Visit `https://vault.yourdomain.com`
2. **Create account**: Register with your email
3. **Import existing data**: Use the import feature if migrating
4. **Install browser extension**: Configure for your domain

### Step 3: Enable Additional Features

#### Two-Factor Authentication

```bash
# Enable 2FA in admin panel or environment variables
# Add to your terraform.tfvars:
extra_env_vars = {
  "YUBICO_CLIENT_ID" = "your_yubico_client_id"
  "YUBICO_SECRET_KEY" = "your_yubico_secret_key"
}
```

#### SMTP Configuration

```bash
# Configure email in admin panel or environment variables
smtp_config = {
  host = "smtp.yourdomain.com"
  from = "noreply@yourdomain.com"
  port = 587
  ssl = true
}
```

## 🚨 Common Installation Issues

### Issue: Terraform State Lock

```bash
# If state is locked
tofu force-unlock LOCK_ID

# Prevention: Always use 'terraform apply' with '-auto-approve' carefully
tofu apply -auto-approve=false
```

### Issue: VPS Connection Problems

```bash
# Check SSH configuration
ssh -vvv root@YOUR_VPS_IP

# Verify SSH key
ssh-add -l
ssh-add ~/.ssh/vaultwarden_rsa

# Check firewall rules
sudo ufw status
sudo iptables -L
```

### Issue: DNS Propagation

```bash
# Check DNS propagation
dig vault.yourdomain.com
nslookup vault.yourdomain.com 8.8.8.8

# Wait for propagation (can take up to 48 hours)
# Use online tools: dnschecker.org
```

### Issue: SSL Certificate Problems

```bash
# Check Let's Encrypt logs
docker logs nginx-proxy
docker logs nginx-proxy-letsencrypt

# Manual certificate request
docker exec nginx-proxy-letsencrypt /app/letsencrypt_service --verbose
```

## 📚 Next Steps

After successful installation:

1. **[Configure monitoring](07-operations.md#monitoring-setup)**
2. **[Set up development environment](06-development-workflow.md)**
3. **[Review security settings](09-security.md)**
4. **[Configure backup testing](07-operations.md#backup-verification)**

---

[← Architecture](02-architecture.md) | [Configuration →](04-configuration.md)

# 🚀 Quick Start Guide

This guide will get you up and running with ValkyrieVault in under 30 minutes.

## 📋 Prerequisites Checklist

Before starting, ensure you have:

- [ ] **AWS Account** with billing enabled
- [ ] **VPS/Server** (1GB RAM minimum, 2GB recommended)
- [ ] **Domain name** with DNS control
- [ ] **GitHub account** for repository and actions
- [ ] **Local development environment**:
  - [ ] Git installed
  - [ ] OpenTofu/Terraform >= 1.6.0
  - [ ] AWS CLI configured
  - [ ] SSH key for VPS access

## ⚡ Express Setup (5 minutes)

### 1. Repository Setup

```bash
# Clone and enter the repository
git clone https://github.com/ton-username/vaultwarden-infra.git
cd vaultwarden-infra

# Create your configuration
cp terraform/environments/production/terraform.tfvars.example \
   terraform/environments/production/terraform.tfvars
```

### 2. Configure AWS

```bash
# Configure AWS CLI (if not already done)
aws configure

# Verify access
aws sts get-caller-identity
```

### 3. Set Your Variables

Edit `terraform/environments/production/terraform.tfvars`:

```hcl
aws_region   = "eu-west-3"           # Your preferred AWS region
project_name = "vaultwarden"         # Keep as is
environment  = "prod"                # Keep as is
domain       = "vault.yourdomain.com" # Your Vaultwarden domain
```

### 4. Deploy Infrastructure

```bash
# Initialize and deploy
cd terraform/environments/production
tofu init
tofu plan
tofu apply
```

### 5. Configure GitHub Secrets

Add these secrets to your GitHub repository:

| Secret Name             | Value                          | Description                  |
| ----------------------- | ------------------------------ | ---------------------------- |
| `AWS_ACCESS_KEY_ID`     | Your AWS access key            | From `aws configure list`    |
| `AWS_SECRET_ACCESS_KEY` | Your AWS secret key            | From AWS credentials         |
| `VPS_HOST_PROD`         | Your VPS IP address            | Server IP for production     |
| `VPS_USER`              | `root`                         | SSH user (usually root)      |
| `VPS_SSH_KEY`           | Your private SSH key           | Complete private key content |
| `DOMAIN_PROD`           | `https://vault.yourdomain.com` | Your Vaultwarden domain      |

### 6. Deploy Application

Push to main branch or manually trigger deployment:

```bash
git add .
git commit -m "feat: initial deployment configuration"
git push origin main
```

## 🎯 Verification

### Check Infrastructure

```bash
# Verify S3 bucket creation
aws s3 ls | grep vaultwarden

# Check secrets
aws secretsmanager list-secrets --query 'SecretList[?Name==`vaultwarden-prod-config`]'
```

### Check Application

1. **Wait for deployment**: Check GitHub Actions for completion
2. **Verify health**: Visit `https://vault.yourdomain.com/alive`
3. **Access admin panel**: Visit `https://vault.yourdomain.com/admin`
4. **Create first user**: Register at `https://vault.yourdomain.com`

## 🔧 First Configuration

### 1. Admin Panel Setup

1. Navigate to `https://vault.yourdomain.com/admin`
2. Use the admin token from AWS Secrets Manager:
   ```bash
   aws secretsmanager get-secret-value \
     --secret-id vaultwarden-prod-config \
     --query SecretString --output text | jq -r .admin_token
   ```
3. Configure your settings (disable user registration, etc.)

### 2. DNS Configuration

Point your domain to your VPS:

```bash
# A record
vault.yourdomain.com. IN A YOUR_VPS_IP

# Optional: CNAME for www
www-vault.yourdomain.com. IN CNAME vault.yourdomain.com.
```

### 3. SSL Certificate

SSL is automatically configured via Let's Encrypt. Verify:

```bash
# Check certificate
curl -I https://vault.yourdomain.com
```

## 🚨 Common Quick Issues

### Infrastructure Deploy Fails

```bash
# Check AWS permissions
aws iam get-user

# Check Terraform state
tofu show
```

### Application Won't Start

```bash
# SSH to your VPS
ssh root@YOUR_VPS_IP

# Check container logs
docker logs vaultwarden

# Check backup service
docker logs vw_backup
```

### Domain Issues

```bash
# Check DNS propagation
dig vault.yourdomain.com

# Check nginx configuration
ssh root@YOUR_VPS_IP
docker exec nginx-proxy cat /etc/nginx/conf.d/default.conf
```

## ➡️ Next Steps

Now that you have a basic setup:

1. **[Configure Development Environment](06-development-workflow.md#development-environment)**
2. **[Set up Monitoring](07-operations.md#monitoring-setup)**
3. **[Configure Backup Verification](07-operations.md#backup-verification)**
4. **[Review Security Settings](09-security.md)**

## 🆘 Need Help?

- **Common issues**: See [Troubleshooting Guide](08-troubleshooting.md)
- **Architecture questions**: Read [Architecture Overview](02-architecture.md)
- **Advanced setup**: Check [Installation Guide](03-installation.md)

---

[← Back to README](../README.md) | [Architecture Overview →](02-architecture.md)

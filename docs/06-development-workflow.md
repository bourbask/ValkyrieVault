# 👨‍💻 Development Workflow

This document outlines the complete development workflow for the ValkyrieVault project.

## 🌊 Git Flow Strategy

We use a **Git Flow** strategy adapted for infrastructure projects with three main environments:

### Branch Strategy

```
main (production)
├── staging (pre-production)
├── develop (development)
├── feature/* (new features)
├── hotfix/* (urgent fixes)
└── release/* (release preparation)
```

### Environment Mapping

| Branch      | Environment     | Auto-Deploy        | Purpose                         |
| ----------- | --------------- | ------------------ | ------------------------------- |
| `main`      | **Production**  | ✅ (with approval) | Live production environment     |
| `staging`   | **Staging**     | ✅ (with review)   | Pre-production testing          |
| `develop`   | **Development** | ✅ (automatic)     | Feature integration and testing |
| `feature/*` | **Local**       | ❌                 | Feature development             |
| `hotfix/*`  | **Staging**     | ✅ (for testing)   | Emergency fixes                 |

## 🚀 Development Environment Setup

### 1. Prerequisites

```bash
# Install required tools
brew install opentofu  # or terraform
brew install awscli
brew install docker
brew install ansible

# Verify installations
tofu version
aws --version
docker --version
ansible --version
```

### 2. Local Development Setup

```bash
# Clone the repository
git clone https://github.com/ton-username/vaultwarden-infra.git
cd vaultwarden-infra

# Setup development branch
git checkout develop

# Install development dependencies
./scripts/setup-dev.sh
```

### 3. Development Environment Configuration

```bash
# Copy development configuration
cp terraform/environments/development/terraform.tfvars.example \
   terraform/environments/development/terraform.tfvars

# Edit development-specific values
cat >> terraform/environments/development/terraform.tfvars << EOF
# Development-specific overrides
aws_region = "eu-west-3"
environment = "dev"
project_name = "vaultwarden"
domain = "dev-vault.yourdomain.com"

# Reduced resources for development
backup_retention_days = {
  hourly  = 1    # 24 hours
  daily   = 7    # 7 days
  monthly = 3    # 3 months
  yearly  = 1    # 1 year
}

enable_monitoring = false
instance_type = "t3.micro"
EOF
```

## 🔄 Development Workflows

### 📝 Feature Development

#### 1. Start New Feature

```bash
# Ensure you're on latest develop
git checkout develop
git pull origin develop

# Create feature branch
git checkout -b feature/backup-encryption-improvements

# Optional: Deploy development environment for testing
./scripts/deploy.sh development
```

#### 2. Development Cycle

```bash
# Make your changes
vim terraform/modules/s3-backup/main.tf

# Test locally (dry run)
cd terraform/environments/development
tofu plan

# Commit frequently with conventional commits
git add .
git commit -m "feat(backup): add encryption key rotation"

# Push and get early feedback
git push origin feature/backup-encryption-improvements
```

#### 3. Testing Your Feature

```bash
# Deploy to development environment
git push origin feature/backup-encryption-improvements

# Create draft PR to trigger development deployment
gh pr create --draft --title "feat: backup encryption improvements" \
  --body "Implements encryption key rotation for backup service"

# Test your changes
./scripts/test-feature.sh backup-encryption
```

#### 4. Finalize Feature

```bash
# Run full test suite
./scripts/run-tests.sh

# Update documentation if needed
vim docs/04-configuration.md

# Final commit
git add .
git commit -m "docs: update backup encryption configuration"

# Mark PR as ready for review
gh pr ready
```

### 🔄 Integration Workflow

#### 1. Merge to Development

```bash
# After PR approval, merge to develop
git checkout develop
git pull origin develop
git merge feature/backup-encryption-improvements
git push origin develop

# Delete feature branch
git branch -d feature/backup-encryption-improvements
git push origin --delete feature/backup-encryption-improvements
```

**Result**: Automatic deployment to development environment

#### 2. Promote to Staging

```bash
# When ready for broader testing
git checkout staging
git pull origin staging
git merge develop
git push origin staging

# Monitor deployment
gh run watch
```

**Result**: Automatic deployment to staging environment

#### 3. Release to Production

```bash
# After thorough testing in staging
git checkout main
git pull origin main
git merge staging
git push origin main

# Monitor production deployment
gh run watch

# Tag the release
git tag -a v1.2.0 -m "Release v1.2.0: backup encryption improvements"
git push origin v1.2.0
```

**Result**: Deployment to production (with approval gates)

### 🚨 Hotfix Workflow

#### 1. Emergency Fix Required

```bash
# Start from main (production)
git checkout main
git pull origin main

# Create hotfix branch
git checkout -b hotfix/critical-security-patch

# Make minimal fix
vim docker/scripts/backup-daily.sh

# Test fix
./scripts/test-hotfix.sh

# Commit with urgency indicator
git add .
git commit -m "fix!: patch critical security vulnerability in backup script"
```

#### 2. Test Hotfix

```bash
# Push and deploy to staging for verification
git push origin hotfix/critical-security-patch

# This can trigger staging deployment for testing
# Verify fix works
./scripts/verify-hotfix.sh
```

#### 3. Deploy Hotfix

```bash
# Merge to main for production
git checkout main
git merge hotfix/critical-security-patch
git push origin main

# Also merge to develop to keep branches in sync
git checkout develop
git merge hotfix/critical-security-patch
git push origin develop

# Clean up
git branch -d hotfix/critical-security-patch
git push origin --delete hotfix/critical-security-patch
```

## 🧪 Testing Strategy

### 1. Local Testing

```bash
# Infrastructure validation
cd terraform/environments/development
tofu validate
tofu plan

# Ansible playbook testing
cd ansible
ansible-playbook --check --diff playbooks/setup-vps.yml

# Docker compose testing
cd docker
docker-compose config
docker-compose -f docker-compose.dev.yml up --dry-run
```

### 2. Integration Testing

```bash
# Full infrastructure test
./scripts/test-infrastructure.sh development

# Application health check
./scripts/health-check.sh https://dev-vault.yourdomain.com

# Backup functionality test
./scripts/test-backup.sh development
```

### 3. Security Testing

```bash
# Infrastructure security scan
./scripts/security-scan.sh

# Docker image vulnerability scan
./scripts/scan-docker-images.sh

# Secrets detection
./scripts/detect-secrets.sh
```

## 🔍 Code Review Guidelines

### Pull Request Requirements

- [ ] **Conventional Commits**: Use conventional commit format
- [ ] **Tests Pass**: All automated tests must pass
- [ ] **Documentation**: Update docs for user-facing changes
- [ ] **Security**: No secrets in code, security impact assessed
- [ ] **Backwards Compatibility**: No breaking changes without major version bump

### Review Checklist

#### Infrastructure Changes

- [ ] Terraform/OpenTofu syntax is valid
- [ ] Resources follow naming conventions
- [ ] No hardcoded values (use variables)
- [ ] Appropriate tags applied
- [ ] State management considerations

#### Application Changes

- [ ] Docker practices followed
- [ ] Security implications assessed
- [ ] Backup impacts considered
- [ ] Monitoring/logging implications

#### Documentation Changes

- [ ] Markdown syntax correct
- [ ] Links work correctly
- [ ] Information is accurate and up-to-date
- [ ] Examples are tested

## 🛠️ Development Scripts

### Setup and Utilities

```bash
# Setup development environment
./scripts/setup-dev.sh

# Deploy specific environment
./scripts/deploy.sh [development|staging|production]

# Run tests
./scripts/run-tests.sh

# Health check
./scripts/health-check.sh [environment]
```

### Debugging and Troubleshooting

```bash
# Debug infrastructure
./scripts/debug-infra.sh [environment]

# Check application logs
./scripts/logs.sh [environment] [service]

# Backup verification
./scripts/verify-backup.sh [environment]
```

## 📊 Development Metrics

### Development KPIs

- **Lead Time**: Feature conception to production deployment
- **Deployment Frequency**: How often we deploy to production
- **Mean Time to Recovery**: Time to resolve issues
- **Change Failure Rate**: Percentage of deployments causing issues

### Quality Gates

- **Code Coverage**: Maintain >80% for scripts and configuration
- **Security Scan**: No high/critical vulnerabilities
- **Performance**: Infrastructure deployment <10 minutes
- **Documentation**: All changes documented

## 🚀 Continuous Improvement

### Regular Reviews

- **Weekly**: Development workflow retrospective
- **Monthly**: Security and performance review
- **Quarterly**: Architecture and tooling assessment

### Automation Opportunities

- [ ] Automated testing expansion
- [ ] Performance benchmarking
- [ ] Security scanning automation
- [ ] Documentation generation

---

[← Configuration](04-configuration.md) | [Operations →](07-operations.md)

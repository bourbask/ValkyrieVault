# 🚀 Deployment Context for Vaultwarden Infrastructure

## Current CI/CD Pipeline Architecture

### GitHub Actions Workflow Structure

```
.github/workflows/
├── deploy.yml              # Main deployment pipeline
├── security-scan.yml       # Security scanning
├── infrastructure-test.yml # Infrastructure testing
└── backup-test.yml         # Backup verification
```

### Deployment Strategy by Environment

#### Environment Mapping

```
Branch → Environment → Deployment Strategy
main     → production  → Blue-Green with approval gates
staging  → staging     → Blue-Green with auto-deploy
develop  → development → Recreate with auto-deploy
```

#### Protection Rules

```yaml
production:
  required_reviewers: 1
  wait_timer: 300 # 5 minute reflection period
  deployment_branches: [main]
  required_status_checks:
    - security-scan
    - infrastructure-plan

staging:
  required_reviewers: 1
  deployment_branches: [staging, hotfix/*]
  required_status_checks:
    - security-scan

development:
  required_reviewers: 0
  deployment_branches: [develop, feature/*]
```

### Deployment Pipeline Stages

#### 1. Pre-Deployment Validation

```yaml
jobs:
  security-scan:
    - Trivy container scanning
    - Checkov infrastructure scanning
    - Secret detection (gitleaks)
    - Dependency vulnerability scan

  infrastructure-plan:
    - Terraform/OpenTofu validation
    - Plan generation and review
    - Cost estimation
    - Security policy compliance

  integration-tests:
    - Ansible playbook syntax check
    - Docker build validation
    - Configuration validation
```

#### 2. Infrastructure Deployment

```yaml
infrastructure-deploy:
  matrix:
    environment: [development, staging, production]
  steps:
    - Terraform workspace selection
    - Plan review and approval
    - Infrastructure apply
    - Output validation
    - State backup
```

#### 3. Application Deployment

```yaml
application-deploy:
  strategy:
    blue-green: # For staging and production
    recreate: # For development
    rolling: # Alternative for non-critical updates
    canary: # For high-risk production changes
```

#### 4. Post-Deployment Verification

```yaml
post-deployment:
  health-checks:
    - Application endpoint validation
    - SSL certificate verification
    - Backup service functionality
    - WebSocket connectivity
    - Performance baseline

  monitoring:
    - Metrics collection activation
    - Alert rule validation
    - Dashboard updates
    - Log aggregation verification
```

## Deployment Strategies Implementation

### Blue-Green Deployment (Production)

```bash
# Current blue-green implementation pattern
CURRENT_ENV=$(docker-compose ps -q | wc -l > 0 && echo "blue" || echo "green")
NEW_ENV=$([ "$CURRENT_ENV" = "blue" ] && echo "green" || echo "blue")

# Deploy new environment
docker-compose -f docker-compose.yml -p "vw-$NEW_ENV" up -d

# Health check new environment
curl -f "http://localhost:8080/alive"

# Switch traffic (nginx configuration)
# Stop old environment
docker-compose -f docker-compose.yml -p "vw-$CURRENT_ENV" down
```

### Rollback Procedures

```yaml
automatic_rollback:
  triggers:
    - Health check failure > 3 attempts
    - Error rate > 10% for 5 minutes
    - Response time > 5s for 2 minutes

manual_rollback:
  process:
    - Identify rollback target (previous deployment)
    - Stop current deployment
    - Restore previous configuration
    - Verify rollback success
    - Update monitoring dashboards
```

### Environment-Specific Configurations

#### Development Deployment

```yaml
development:
  deployment_strategy: recreate
  backup_retention: minimal (1 day hourly, 7 days daily)
  monitoring: basic
  ssl: self-signed or staging certificates
  resource_limits: reduced (256MB RAM, 0.5 CPU)
```

#### Staging Deployment

```yaml
staging:
  deployment_strategy: blue_green
  backup_retention: medium (1 day hourly, 14 days daily)
  monitoring: full (without alerting)
  ssl: letsencrypt_staging
  resource_limits: production_like
```

#### Production Deployment

```yaml
production:
  deployment_strategy: blue_green
  backup_retention: full (48h hourly, 30d daily, 12m monthly, 5y yearly)
  monitoring: comprehensive_with_alerting
  ssl: letsencrypt_production
  resource_limits: optimized
  additional_security: enhanced_logging, intrusion_detection
```

## Release Management

### Version Strategy

```
Semantic Versioning: MAJOR.MINOR.PATCH
- MAJOR: Breaking changes (rare)
- MINOR: New features, environment upgrades
- PATCH: Bug fixes, security updates, patches

Tags: v1.2.3
Branches: release/v1.2.3
```

### Release Pipeline

```yaml
release_process:
  1. Feature Development:
    - Feature branches from develop
    - Pull request to develop
    - Auto-deploy to development

  2. Integration Testing:
    - Merge develop to staging
    - Auto-deploy to staging
    - Manual testing and validation

  3. Production Release:
    - Merge staging to main
    - Manual approval required
    - Blue-green deployment to production
    - Post-deployment verification

  4. Hotfix Process:
    - Hotfix branch from main
    - Deploy to staging for testing
    - Fast-track to production
    - Back-merge to develop
```

### Deployment Monitoring

#### Key Metrics

```yaml
deployment_metrics:
  lead_time:
    - Commit to deployment time
    - Feature development time
    - Review and approval time

  deployment_frequency:
    - Deployments per week/month
    - Success rate percentage
    - Rollback frequency

  reliability:
    - Mean time to recovery (MTTR)
    - Change failure rate
    - Availability percentage
```

#### Health Checks

```bash
# Application health validation
curl -f https://vault.yourdomain.com/alive
curl -f https://vault.yourdomain.com/api/config

# Infrastructure health
docker ps --filter "status=running" | grep vaultwarden
aws s3 ls s3://vaultwarden-prod-backups/
kubectl get pods -n vaultwarden  # If using Kubernetes

# Security validation
nmap -p 80,443 vault.yourdomain.com
sslscan vault.yourdomain.com
```

### Disaster Recovery Deployment

#### Recovery Time Objectives (RTO)

- **Critical**: < 1 hour (complete service restoration)
- **Major**: < 4 hours (full feature restoration)
- **Minor**: < 24 hours (non-critical feature restoration)

#### Recovery Point Objectives (RPO)

- **Database**: < 1 hour (hourly backups)
- **Configuration**: < 15 minutes (Git-based recovery)
- **Infrastructure**: < 30 minutes (IaC recreation)

#### DR Deployment Process

```bash
# 1. Infrastructure Recreation
cd terraform/environments/production
tofu init
tofu apply -auto-approve

# 2. Data Restoration
./scripts/restore-backup.sh production latest

# 3. Application Deployment
docker-compose up -d

# 4. Verification
./scripts/disaster-recovery-test.sh
```

### Compliance and Audit

#### Deployment Audit Trail

- Git commit history and tags
- GitHub Actions execution logs
- Terraform state change logs
- Container deployment logs
- Security scan results
- Approval and review records

#### Change Management

```yaml
change_categories:
  emergency:
    approval: security_team_lead
    documentation: post_change
    testing: production_verification

  standard:
    approval: team_lead + peer_review
    documentation: pre_change
    testing: staging_validation

  routine:
    approval: peer_review
    documentation: automated
    testing: automated_pipeline
```

# 🤝 Contributing Guide

Welcome to the ValkyrieVault project! This guide will help you contribute effectively whether you're fixing bugs, adding features, improving documentation, or enhancing security.

## 🎯 Ways to Contribute

### 🐛 Bug Fixes & Issues

- Report bugs with detailed reproduction steps
- Fix existing issues from our GitHub Issues
- Improve error handling and edge cases

### ✨ New Features

- Infrastructure improvements and optimizations
- New deployment strategies or environments
- Enhanced security features
- Better monitoring and observability

### 📚 Documentation

- Improve existing documentation clarity
- Add missing configuration examples
- Create tutorials and how-to guides
- Translate documentation to other languages

### 🔒 Security

- Security audits and vulnerability reports
- Hardening improvements
- New security monitoring features
- Compliance and best practices

## 🚀 Getting Started

### Development Environment Setup

```bash
# 1. Fork the repository on GitHub
# 2. Clone your fork locally
git clone https://github.com/YOUR_USERNAME/vaultwarden-infra.git
cd vaultwarden-infra

# 3. Set up upstream remote
git remote add upstream https://github.com/ORIGINAL_OWNER/vaultwarden-infra.git

# 4. Create development environment
cp terraform/environments/development/terraform.tfvars.example \
   terraform/environments/development/terraform.tfvars

# Edit with your development values
vim terraform/environments/development/terraform.tfvars

# 5. Install development dependencies
./scripts/setup-dev-environment.sh
```

### Development Tools Setup

```bash
#!/bin/bash
# scripts/setup-dev-environment.sh

echo "🛠️ Setting up development environment"

# Install required tools
if [[ "$OSTYPE" == "darwin"* ]]; then
    # macOS
    brew install \
        opentofu \
        terraform \
        awscli \
        ansible \
        docker \
        gh \
        pre-commit \
        shellcheck \
        yamllint \
        hadolint
else
    # Linux (Ubuntu/Debian)
    sudo apt update
    sudo apt install -y \
        curl \
        git \
        python3-pip \
        docker.io \
        shellcheck

    # OpenTofu
    curl -fsSL https://get.opentofu.org/install.sh | sudo bash

    # AWS CLI
    curl "https://awscli.amazonaws.com/awscli-exe-linux-x86_64.zip" -o "awscliv2.zip"
    unzip awscliv2.zip && sudo ./aws/install

    # Ansible
    pip3 install ansible

    # GitHub CLI
    curl -fsSL https://cli.github.com/packages/githubcli-archive-keyring.gpg | sudo dd of=/usr/share/keyrings/githubcli-archive-keyring.gpg
    echo "deb [arch=$(dpkg --print-architecture) signed-by=/usr/share/keyrings/githubcli-archive-keyring.gpg] https://cli.github.com/packages stable main" | sudo tee /etc/apt/sources.list.d/github-cli.list
    sudo apt update && sudo apt install gh
fi

# Install pre-commit hooks
pip3 install pre-commit
pre-commit install

# Setup development aliases
cat >> ~/.bashrc << 'EOF'
# Vaultwarden development aliases
alias vw-dev='cd ~/vaultwarden-infra && docker-compose -f docker-compose.dev.yml'
alias vw-logs='docker logs vaultwarden --tail 50 -f'
alias vw-backup='./scripts/backup-manual.sh development'
alias vw-test='./scripts/run-tests.sh'
EOF

echo "✅ Development environment setup completed"
echo "ℹ️  Please restart your shell or run: source ~/.bashrc"
```

### Pre-commit Hooks Setup

```yaml
# .pre-commit-config.yaml
repos:
  - repo: https://github.com/pre-commit/pre-commit-hooks
    rev: v4.4.0
    hooks:
      - id: trailing-whitespace
      - id: end-of-file-fixer
      - id: check-yaml
      - id: check-added-large-files
      - id: check-merge-conflict
      - id: check-json
      - id: pretty-format-json
        args: ["--autofix", "--no-sort-keys"]

  - repo: https://github.com/antonbabenko/pre-commit-terraform
    rev: v1.83.5
    hooks:
      - id: terraform_fmt
      - id: terraform_validate
      - id: terraform_docs
      - id: terraform_tflint

  - repo: https://github.com/shellcheck-py/shellcheck-py
    rev: v0.9.0.6
    hooks:
      - id: shellcheck

  - repo: https://github.com/adrienverge/yamllint
    rev: v1.32.0
    hooks:
      - id: yamllint
        args: [-c=.yamllint]

  - repo: https://github.com/hadolint/hadolint
    rev: v2.12.0
    hooks:
      - id: hadolint-docker
```

## 📝 Development Workflow

### Branching Strategy

```bash
# Feature development
git checkout develop
git pull upstream develop
git checkout -b feature/your-feature-name

# Work on your feature
# ... make changes ...

# Commit with conventional commits
git add .
git commit -m "feat(backup): add encryption key rotation"
```

### Conventional Commits

We use [Conventional Commits](https://www.conventionalcommits.org/) for all commit messages:

```
<type>[optional scope]: <description>

[optional body]

[optional footer(s)]
```

#### Types

- `feat`: New features
- `fix`: Bug fixes
- `docs`: Documentation changes
- `style`: Code style changes (formatting, etc.)
- `refactor`: Code refactoring
- `test`: Adding or updating tests
- `chore`: Maintenance tasks
- `security`: Security improvements
- `perf`: Performance improvements

#### Examples

```bash
feat(terraform): add multi-region backup support
fix(docker): resolve container restart loop issue
docs(readme): add troubleshooting section
security(nginx): implement advanced rate limiting
chore(deps): update terraform provider versions
```

### Testing Your Changes

```bash
#!/bin/bash
# scripts/test-changes.sh

echo "🧪 Testing your changes"

# 1. Lint and format checks
echo "📝 Running linting checks"
pre-commit run --all-files

# 2. Terraform validation
echo "🔧 Validating Terraform configurations"
for env in development staging production; do
    cd "terraform/environments/$env"
    tofu init -backend=false
    tofu validate
    cd ../../..
done

# 3. Docker build tests
echo "🐳 Testing Docker builds"
docker build -t vaultwarden-infra-test:latest -f docker/Dockerfile.backup .

# 4. Ansible syntax check
echo "📋 Checking Ansible playbooks"
ansible-playbook --syntax-check ansible/playbooks/*.yml

# 5. Script tests
echo "📚 Testing shell scripts"
shellcheck scripts/*.sh

# 6. Integration tests (if development environment available)
if [[ -f "terraform/environments/development/.terraform/terraform.tfstate" ]]; then
    echo "🔄 Running integration tests"
    ./tests/integration/basic-tests.sh
fi

echo "✅ All tests completed"
```

## 🔄 Pull Request Process

### Creating a Pull Request

1. **Ensure your branch is up to date**:

   ```bash
   git checkout develop
   git pull upstream develop
   git checkout your-feature-branch
   git rebase develop
   ```

2. **Run tests and checks**:

   ```bash
   ./scripts/test-changes.sh
   ```

3. **Push your changes**:

   ```bash
   git push origin your-feature-branch
   ```

4. **Create PR using GitHub CLI or web interface**:
   ```bash
   gh pr create --title "feat: add backup encryption rotation" \
                --body-file pr-template.md \
                --base develop \
                --head your-feature-branch
   ```

### Pull Request Template

```markdown
## 📋 Description

Brief description of changes made.

## 🎯 Type of Change

- [ ] 🐛 Bug fix (non-breaking change which fixes an issue)
- [ ] ✨ New feature (non-breaking change which adds functionality)
- [ ] 💥 Breaking change (fix or feature that would cause existing functionality to not work as expected)
- [ ] 📚 Documentation update
- [ ] 🔒 Security improvement
- [ ] 🔧 Infrastructure optimization

## 🧪 Testing

- [ ] Tests pass locally
- [ ] Pre-commit hooks pass
- [ ] Manual testing completed
- [ ] Documentation updated

## 📸 Screenshots (if applicable)

Add screenshots or logs showing your changes working.

## ✅ Checklist

- [ ] My code follows the style guidelines of this project
- [ ] I have performed a self-review of my own code
- [ ] I have commented my code, particularly in hard-to-understand areas
- [ ] I have made corresponding changes to the documentation
- [ ] My changes generate no new warnings
- [ ] I have added tests that prove my fix is effective or that my feature works
- [ ] New and existing unit tests pass locally with my changes
- [ ] Any dependent changes have been merged and published

## 🔗 Related Issues

Fixes #(issue number)
```

### Review Process

1. **Automated Checks**: All PRs must pass automated tests and security scans
2. **Peer Review**: At least one maintainer must approve the PR
3. **Documentation Review**: Documentation changes are reviewed for clarity and completeness
4. **Security Review**: Security-related changes undergo additional security review
5. **Testing**: Changes are tested in staging environment before production merge

## 🏗️ Infrastructure Contributions

### Adding New Terraform Modules

```hcl
# terraform/modules/new-module/main.tf
terraform {
  required_version = ">= 1.0"
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
  }
}

variable "environment" {
  description = "Environment name"
  type        = string
  validation {
    condition     = contains(["dev", "staging", "prod"], var.environment)
    error_message = "Environment must be dev, staging, or prod."
  }
}

variable "project_name" {
  description = "Project name"
  type        = string
}

# Your module resources here...

output "module_output" {
  description = "Description of what this outputs"
  value       = aws_resource.example.id
}
```

### Module Documentation

````markdown
# New Module

## Description

Brief description of what this module does.

## Usage

```hcl
module "new_module" {
  source = "../../modules/new-module"

  environment  = "prod"
  project_name = "vaultwarden"
}
```
````

## Inputs

| Name        | Description      | Type     | Default | Required |
| ----------- | ---------------- | -------- | ------- | -------- |
| environment | Environment name | `string` | n/a     | yes      |

## Outputs

| Name          | Description           |
| ------------- | --------------------- |
| module_output | Description of output |

````

## 🐳 Docker Contributions

### Adding New Container Services

```dockerfile
# docker/Dockerfile.newservice
FROM alpine:3.18

# Security: Create non-root user
RUN addgroup -g 1001 appgroup && \
    adduser -u 1001 -G appgroup -s /bin/sh -D appuser

# Install dependencies
RUN apk add --no-cache \
    ca-certificates \
    curl \
    bash

# Security: Set proper file permissions
COPY --chown=appuser:appgroup scripts/ /scripts/
RUN chmod +x /scripts/*.sh

# Security: Use non-root user
USER appuser

# Health check
HEALTHCHECK --interval=30s --timeout=10s --start-period=5s --retries=3 \
    CMD curl -f http://localhost:8080/health || exit 1

EXPOSE 8080
CMD ["/scripts/entrypoint.sh"]
````

### Docker Compose Service Addition

```yaml
# Addition to docker-compose.yml
new-service:
  build:
    context: .
    dockerfile: docker/Dockerfile.newservice
  container_name: vw_new_service
  restart: unless-stopped

  # Security configurations
  user: "1001:1001"
  read_only: true
  tmpfs:
    - /tmp
  cap_drop:
    - ALL
  cap_add:
    - NET_BIND_SERVICE
  security_opt:
    - no-new-privileges:true

  environment:
    - SERVICE_CONFIG=${SERVICE_CONFIG}

  networks:
    - vaultwarden_net

  depends_on:
    vaultwarden:
      condition: service_healthy
```

## 📚 Documentation Contributions

### Documentation Standards

1. **Clear Structure**: Use consistent heading hierarchy
2. **Code Examples**: Provide working, tested examples
3. **Cross-References**: Link related sections
4. **Screenshots**: Include visual aids where helpful
5. **Keep Updated**: Ensure accuracy with current versions

### Writing Style Guide

- **Tone**: Professional but approachable
- **Voice**: Use active voice when possible
- **Clarity**: Prefer simple, clear language
- **Examples**: Always provide concrete examples
- **Completeness**: Include prerequisites and next steps

## 🔒 Security Contributions

### Security Review Process

1. **Threat Modeling**: Consider security implications
2. **Code Review**: Security-focused code review
3. **Testing**: Security testing and validation
4. **Documentation**: Security considerations documented

### Reporting Security Issues

**Please do not report security vulnerabilities through public GitHub issues.**

Instead:

1. Email security@yourdomain.com
2. Include detailed description and reproduction steps
3. Allow reasonable time for response before disclosure
4. Follow responsible disclosure practices

### Security Contribution Examples

```bash
# Example: Adding security monitoring
#!/bin/bash
# scripts/security-monitor.sh

# Monitor for suspicious activities
monitor_failed_logins() {
    tail -f /var/log/auth.log | while read line; do
        if echo "$line" | grep -q "Failed password"; then
            # Count recent failures
            recent_failures=$(grep "Failed password" /var/log/auth.log | \
                grep "$(date '+%b %d')" | wc -l)

            if [ "$recent_failures" -gt 5 ]; then
                alert_security_team "Multiple failed login attempts detected"
            fi
        fi
    done
}
```

## 🎯 Specialized Contributions

### Performance Optimizations

When contributing performance improvements:

1. **Benchmark**: Include before/after performance metrics
2. **Documentation**: Document the optimization and its impact
3. **Testing**: Verify no functionality regressions
4. **Monitoring**: Add metrics to track ongoing performance

### Monitoring & Observability

```yaml
# Example: Adding new Prometheus metrics
# monitoring/custom-metrics.yml
apiVersion: v1
kind: ConfigMap
metadata:
  name: custom-metrics
data:
  custom.yml: |
    groups:
    - name: vaultwarden.custom
      rules:
      - alert: CustomAlert
        expr: custom_metric > threshold
        for: 5m
        labels:
          severity: warning
        annotations:
          summary: "Custom metric exceeded threshold"
```

## 🏆 Recognition

### Contributors

We recognize all types of contributions:

- **Code Contributors**: Listed in AUTHORS.md
- **Documentation Contributors**: Credited in documentation
- **Security Contributors**: Acknowledged in security changelog
- **Community Contributors**: Recognized in community discussions

### Contribution Rewards

- **Commit Rights**: Regular contributors may be granted commit access
- **Mentorship**: Experienced contributors can mentor newcomers
- **Speaking Opportunities**: Present your contributions at conferences
- **Professional References**: Strong contributors receive professional references

## 📞 Getting Help

### Communication Channels

- **GitHub Discussions**: General questions and design discussions
- **GitHub Issues**: Bug reports and feature requests
- **Email**: security@yourdomain.com for security issues
- **Matrix/Discord**: Community chat (if available)

### Office Hours

- **Weekly Office Hours**: Thursdays 2-3 PM UTC
- **Contributor Sync**: First Monday of each month
- **Security Review**: By appointment for security contributions

### Mentorship Program

New contributors can request mentorship:

1. Comment on a "good first issue"
2. Tag @maintainers in your comment
3. A maintainer will be assigned to guide you
4. Regular check-ins and code review support

## 📋 Issue Templates

### Bug Report Template

```markdown
**Describe the bug**
A clear and concise description of what the bug is.

**To Reproduce**
Steps to reproduce the behavior:

1. Go to '...'
2. Click on '....'
3. Scroll down to '....'
4. See error

**Expected behavior**
A clear and concise description of what you expected to happen.

**Environment:**

- OS: [e.g. Ubuntu 22.04]
- Docker version: [e.g. 20.10.17]
- Vaultwarden version: [e.g. 1.30.1]
- Browser [e.g. chrome, safari]

**Additional context**
Add any other context about the problem here.
```

### Feature Request Template

```markdown
**Is your feature request related to a problem? Please describe.**
A clear and concise description of what the problem is. Ex. I'm always frustrated when [...]

**Describe the solution you'd like**
A clear and concise description of what you want to happen.

**Describe alternatives you've considered**
A clear and concise description of any alternative solutions or features you've considered.

**Additional context**
Add any other context or screenshots about the feature request here.
```

---

Thank you for contributing to ValkyrieVault! Your contributions help make this project better for everyone. 🙏

[← Security](09-security.md) | [Back to README](../README.md)

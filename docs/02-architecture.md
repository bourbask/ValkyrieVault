# 🏗️ Architecture Overview

This document provides a comprehensive overview of the ValkyrieVault architecture, including system design, component interactions, and deployment patterns.

## 🎯 Design Principles

### Core Principles

- **Security First**: End-to-end encryption, zero-trust architecture
- **Resilience**: Multi-tier backup strategy, disaster recovery
- **Scalability**: Horizontal scaling capabilities, performance optimization
- **Observability**: Comprehensive monitoring, logging, and alerting
- **Automation**: Infrastructure as Code, GitOps deployment

### Architecture Patterns

- **Infrastructure as Code**: All infrastructure defined in OpenTofu/Terraform
- **GitOps**: Deployments driven by Git commits and pull requests
- **Multi-Environment**: Separate environments for development, staging, production
- **Microservices**: Containerized application with separate backup service
- **Event-Driven**: Automated responses to system events and alerts

## 🏛️ System Architecture

### High-Level Architecture

```mermaid
graph TB
    subgraph "External Users"
        U1[Web Browser]
        U2[Mobile App]
        U3[Browser Extension]
    end

    subgraph "DNS & CDN"
        DNS[Cloudflare DNS]
        CDN[Cloudflare CDN]
    end

    subgraph "Load Balancer & Proxy"
        LB[Nginx Proxy Manager]
        SSL[Let's Encrypt SSL]
    end

    subgraph "Application Layer"
        VW[Vaultwarden Container]
        WS[WebSocket Server]
        API[REST API]
    end

    subgraph "Data Layer"
        DB[(SQLite Database)]
        FILES[File Attachments]
        CACHE[Application Cache]
    end

    subgraph "Backup Systems"
        BS[Backup Service]
        CRON[Cron Scheduler]
    end

    subgraph "AWS Infrastructure"
        S3[S3 Backup Storage]
        SM[Secrets Manager]
        IAM[IAM Roles & Policies]
        CW[CloudWatch Logs]
    end

    subgraph "Monitoring & Observability"
        PROM[Prometheus]
        GRAF[Grafana]
        ALERT[Alertmanager]
        LOGS[Log Aggregation]
    end

    subgraph "CI/CD Pipeline"
        GH[GitHub Repository]
        GA[GitHub Actions]
        TOFU[OpenTofu/Terraform]
    end

    U1 --> DNS
    U2 --> DNS
    U3 --> DNS
    DNS --> CDN
    CDN --> LB
    LB --> SSL
    SSL --> VW

    VW --> WS
    VW --> API
    VW --> DB
    VW --> FILES
    VW --> CACHE

    BS --> CRON
    BS --> DB
    BS --> FILES
    BS --> S3
    BS --> SM

    VW --> PROM
    BS --> PROM
    PROM --> GRAF
    PROM --> ALERT

    GH --> GA
    GA --> TOFU
    TOFU --> S3
    TOFU --> SM
    TOFU --> IAM

    LOGS --> CW
```

### Network Architecture

```mermaid
graph LR
    subgraph "Internet"
        INT[Internet Traffic]
    end

    subgraph "VPS Network"
        subgraph "External Zone"
            FW[Firewall/UFW]
            PROXY[Nginx Proxy]
        end

        subgraph "Application Zone"
            APP[Vaultwarden App]
            BACKUP[Backup Service]
        end

        subgraph "Data Zone"
            DB[(Database)]
            VOL[Docker Volumes]
        end
    end

    subgraph "AWS Cloud"
        S3[S3 Storage]
        SECRETS[Secrets Manager]
    end

    INT --> FW
    FW --> PROXY
    PROXY --> APP
    APP --> DB
    APP --> VOL
    BACKUP --> DB
    BACKUP --> S3
    APP --> SECRETS
    BACKUP --> SECRETS

    style INT fill:#ff6b6b
    style FW fill:#4ecdc4
    style APP fill:#45b7d1
    style S3 fill:#96ceb4
```

## 🔧 Component Deep Dive

### Vaultwarden Application

```yaml
# Core application specifications
Container: vaultwarden/server:latest
Resources:
  CPU: 0.5-1.0 cores
  Memory: 256-512MB
  Storage: 1-10GB (grows with users)

Network:
  Internal Port: 80 (HTTP)
  WebSocket Port: 3012
  External Port: 443 (HTTPS via proxy)

Environment Variables:
  - DOMAIN: https://vault.yourdomain.com
  - DATABASE_URL: sqlite:///data/db.sqlite3
  - ADMIN_TOKEN: <generated-secure-token>
  - WEBSOCKET_ENABLED: true
  - SENDS_ALLOWED: true
  - ORG_CREATION_USERS: all
```

### Backup Service Architecture

```mermaid
graph TD
    subgraph "Backup Service Container"
        CRON[Cron Daemon]
        SCRIPTS[Backup Scripts]
        TOOLS[Backup Tools]
    end

    subgraph "Backup Workflows"
        H[Hourly Backup]
        D[Daily Backup]
        M[Monthly Archive]
        V[Verification]
    end

    subgraph "Storage Tiers"
        L1[Local Temp]
        L2[S3 Standard]
        L3[S3 Glacier]
        L4[S3 Deep Archive]
    end

    CRON --> H
    CRON --> D
    CRON --> M
    CRON --> V

    H --> SCRIPTS
    D --> SCRIPTS
    M --> SCRIPTS
    V --> SCRIPTS

    SCRIPTS --> TOOLS
    TOOLS --> L1
    L1 --> L2
    L2 --> L3
    L3 --> L4

    style H fill:#ffd93d
    style D fill:#6bcf7f
    style M fill:#4d96ff
    style V fill:#ff6b6b
```

### Database Architecture

```mermaid
erDiagram
    USERS ||--o{ CIPHERS : owns
    USERS ||--o{ FOLDERS : creates
    USERS ||--o{ DEVICES : registers
    USERS ||--o{ ORGANIZATIONS : belongs_to

    ORGANIZATIONS ||--o{ ORG_USERS : contains
    ORGANIZATIONS ||--o{ ORG_POLICIES : has
    ORGANIZATIONS ||--o{ COLLECTIONS : owns

    COLLECTIONS ||--o{ COLLECTION_CIPHERS : contains
    CIPHERS ||--o{ ATTACHMENTS : has

    USERS {
        uuid id PK
        string email UK
        string password_hash
        string salt
        datetime created_at
        datetime updated_at
    }

    CIPHERS {
        uuid id PK
        uuid user_id FK
        int type
        text data_encrypted
        datetime created_at
        datetime updated_at
    }

    ATTACHMENTS {
        uuid id PK
        uuid cipher_id FK
        string file_name
        int file_size
        text key_encrypted
    }
```

## 🌐 Multi-Environment Architecture

### Environment Segregation

```mermaid
graph TB
    subgraph "Development Environment"
        DEV_VPS[Dev VPS]
        DEV_DB[(Dev Database)]
        DEV_S3[Dev S3 Bucket]
    end

    subgraph "Staging Environment"
        STAG_VPS[Staging VPS]
        STAG_DB[(Staging Database)]
        STAG_S3[Staging S3 Bucket]
    end

    subgraph "Production Environment"
        PROD_VPS[Production VPS]
        PROD_DB[(Production Database)]
        PROD_S3[Production S3 Bucket]
        PROD_S3_BACKUP[Backup S3 Bucket]
    end

    subgraph "Shared Services"
        SECRETS[AWS Secrets Manager]
        MONITORING[Centralized Monitoring]
        LOGS[Centralized Logging]
    end

    DEV_VPS --> DEV_DB
    DEV_VPS --> DEV_S3
    STAG_VPS --> STAG_DB
    STAG_VPS --> STAG_S3
    PROD_VPS --> PROD_DB
    PROD_VPS --> PROD_S3
    PROD_VPS --> PROD_S3_BACKUP

    DEV_VPS --> SECRETS
    STAG_VPS --> SECRETS
    PROD_VPS --> SECRETS

    DEV_VPS --> MONITORING
    STAG_VPS --> MONITORING
    PROD_VPS --> MONITORING

    style DEV_VPS fill:#ffd93d
    style STAG_VPS fill:#6bcf7f
    style PROD_VPS fill:#ff6b6b
```

### Resource Allocation by Environment

| Component            | Development           | Staging                 | Production                          |
| -------------------- | --------------------- | ----------------------- | ----------------------------------- |
| **VPS Size**         | 1GB RAM, 1 CPU        | 2GB RAM, 1 CPU          | 4GB RAM, 2 CPU                      |
| **Storage**          | 10GB SSD              | 20GB SSD                | 50GB SSD                            |
| **Backup Retention** | 1 day hourly, 7 daily | 2 days hourly, 14 daily | 2 days hourly, 30 daily, 12 monthly |
| **Monitoring**       | Basic                 | Enhanced                | Full + Alerting                     |
| **SSL Certificate**  | Let's Encrypt         | Let's Encrypt           | Let's Encrypt + Monitoring          |

## 🔒 Security Architecture

### Defense in Depth

```mermaid
graph TD
    subgraph "Perimeter Security"
        FW[Firewall Rules]
        DDoS[DDoS Protection]
        GEO[Geo-blocking]
    end

    subgraph "Network Security"
        VPN[VPN Access]
        SSH[SSH Key Auth]
        TLS[TLS 1.3 Encryption]
    end

    subgraph "Application Security"
        AUTH[2FA Authentication]
        RBAC[Role-Based Access]
        API[API Rate Limiting]
    end

    subgraph "Data Security"
        ENC[End-to-End Encryption]
        HASH[Argon2 Hashing]
        BACKUP_ENC[Backup Encryption]
    end

    subgraph "Operational Security"
        AUDIT[Audit Logging]
        MON[Security Monitoring]
        SCAN[Vulnerability Scanning]
    end

    FW --> VPN
    DDoS --> SSH
    GEO --> TLS

    VPN --> AUTH
    SSH --> RBAC
    TLS --> API

    AUTH --> ENC
    RBAC --> HASH
    API --> BACKUP_ENC

    ENC --> AUDIT
    HASH --> MON
    BACKUP_ENC --> SCAN

    style FW fill:#ff6b6b
    style AUTH fill:#4ecdc4
    style ENC fill:#45b7d1
    style AUDIT fill:#96ceb4
```

### Encryption Architecture

```mermaid
graph LR
    subgraph "Client Side"
        MASTER[Master Password]
        KEY[Master Key]
        ENC_KEY[Encryption Key]
    end

    subgraph "Transport"
        TLS[TLS 1.3]
        CERT[SSL Certificate]
    end

    subgraph "Server Side"
        HASH[Password Hash]
        SALT[Random Salt]
        CIPHER[Encrypted Ciphers]
    end

    subgraph "Backup Encryption"
        GPG[GPG Encryption]
        BACKUP_KEY[Backup Key]
        S3_ENC[S3 Encryption]
    end

    MASTER --> KEY
    KEY --> ENC_KEY
    ENC_KEY --> TLS
    TLS --> CERT

    CERT --> HASH
    HASH --> SALT
    SALT --> CIPHER

    CIPHER --> GPG
    GPG --> BACKUP_KEY
    BACKUP_KEY --> S3_ENC

    style MASTER fill:#ff6b6b
    style TLS fill:#4ecdc4
    style GPG fill:#45b7d1
```

## 📊 Data Flow Architecture

### User Registration & Authentication

```mermaid
sequenceDiagram
    participant C as Client
    participant VW as Vaultwarden
    participant DB as Database
    participant S3 as S3 Backup

    C->>VW: Register with email/password
    VW->>VW: Generate salt
    VW->>VW: Hash password (Argon2)
    VW->>DB: Store user record
    DB-->>VW: User ID
    VW-->>C: Registration success

    Note over C,S3: Authentication Flow
    C->>VW: Login request
    VW->>DB: Verify credentials
    DB-->>VW: User verified
    VW->>VW: Generate JWT token
    VW-->>C: Auth token + vault data

    Note over VW,S3: Backup trigger
    VW->>S3: Backup user data (encrypted)
```

### Data Synchronization

```mermaid
sequenceDiagram
    participant C as Client App
    participant VW as Vaultwarden
    participant DB as Database
    participant BS as Backup Service
    participant S3 as S3 Storage

    C->>VW: Create/Update cipher
    VW->>VW: Validate & encrypt
    VW->>DB: Store encrypted data
    VW->>VW: Update sync revision
    VW-->>C: Sync response

    Note over BS,S3: Hourly backup process
    BS->>DB: Backup database
    BS->>BS: Compress & encrypt
    BS->>S3: Upload to S3

    Note over C,S3: Multi-device sync
    C->>VW: Check sync revision
    VW->>DB: Compare revisions
    VW-->>C: Delta sync data
```

## 🚀 Deployment Architecture

### GitOps Workflow

```mermaid
graph TD
    subgraph "Developer Workflow"
        DEV[Developer]
        FEAT[Feature Branch]
        PR[Pull Request]
    end

    subgraph "CI/CD Pipeline"
        TEST[Automated Tests]
        PLAN[Terraform Plan]
        SECURITY[Security Scan]
        REVIEW[Code Review]
    end

    subgraph "Deployment Stages"
        DEV_DEPLOY[Dev Deployment]
        STAG_DEPLOY[Staging Deployment]
        PROD_DEPLOY[Prod Deployment]
    end

    subgraph "Infrastructure"
        TOFU[OpenTofu Apply]
        ANSIBLE[Ansible Playbook]
        DOCKER[Docker Deploy]
    end

    DEV --> FEAT
    FEAT --> PR
    PR --> TEST
    TEST --> PLAN
    PLAN --> SECURITY
    SECURITY --> REVIEW

    REVIEW --> DEV_DEPLOY
    DEV_DEPLOY --> STAG_DEPLOY
    STAG_DEPLOY --> PROD_DEPLOY

    DEV_DEPLOY --> TOFU
    STAG_DEPLOY --> TOFU
    PROD_DEPLOY --> TOFU

    TOFU --> ANSIBLE
    ANSIBLE --> DOCKER

    style DEV fill:#ffd93d
    style TEST fill:#4ecdc4
    style PROD_DEPLOY fill:#ff6b6b
```

### Container Orchestration

```yaml
# Docker Compose Architecture
version: "3.8"

networks:
  vaultwarden_network:
    driver: bridge
    ipam:
      config:
        - subnet: 172.20.0.0/16

volumes:
  vw_data:
    driver: local
    driver_opts:
      type: none
      o: bind
      device: /opt/vaultwarden/data

services:
  nginx-proxy:
    image: nginxproxy/nginx-proxy:1.0
    networks:
      vaultwarden_network:
        ipv4_address: 172.20.0.10

  vaultwarden:
    image: vaultwarden/server:latest
    networks:
      vaultwarden_network:
        ipv4_address: 172.20.0.20
    depends_on:
      - nginx-proxy

  backup-service:
    image: alpine:latest
    networks:
      vaultwarden_network:
        ipv4_address: 172.20.0.30
    depends_on:
      - vaultwarden

  prometheus:
    image: prom/prometheus:latest
    networks:
      vaultwarden_network:
        ipv4_address: 172.20.0.40
```

## 📐 Scaling Considerations

### Vertical Scaling Limits

| Metric                  | Small Instance | Medium Instance | Large Instance |
| ----------------------- | -------------- | --------------- | -------------- |
| **Users**               | 1-50           | 50-200          | 200-1000       |
| **CPU**                 | 1 core         | 2 cores         | 4 cores        |
| **Memory**              | 1GB            | 2GB             | 4GB            |
| **Storage**             | 10GB           | 25GB            | 50GB           |
| **Concurrent Sessions** | 10             | 50              | 200            |

### Horizontal Scaling Options

```mermaid
graph TB
    subgraph "Load Balancer Tier"
        LB[HAProxy/Nginx]
        SSL[SSL Termination]
    end

    subgraph "Application Tier"
        VW1[Vaultwarden 1]
        VW2[Vaultwarden 2]
        VW3[Vaultwarden 3]
    end

    subgraph "Database Tier"
        PRIMARY[(Primary DB)]
        REPLICA1[(Read Replica 1)]
        REPLICA2[(Read Replica 2)]
    end

    subgraph "Storage Tier"
        S3[Shared File Storage]
        BACKUP[Distributed Backup]
    end

    LB --> VW1
    LB --> VW2
    LB --> VW3

    VW1 --> PRIMARY
    VW2 --> REPLICA1
    VW3 --> REPLICA2

    VW1 --> S3
    VW2 --> S3
    VW3 --> S3

    PRIMARY --> BACKUP
    REPLICA1 --> BACKUP
    REPLICA2 --> BACKUP
```

_Note: Vaultwarden currently doesn't support true horizontal scaling due to SQLite limitations. This diagram shows a potential future PostgreSQL-based architecture._

---

[← Quick Start](01-quick-start.md) | [Installation Guide →](03-installation.md)

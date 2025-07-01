# 🐳 Docker/Container Context for ValkyrieVault

## Container Security Standards

### Base Image Requirements

- **Primary**: Alpine Linux 3.18+ for minimal attack surface
- **Alternative**: Ubuntu 22.04 only if Alpine not compatible
- **Forbidden**: Latest tags, Debian/CentOS unless specifically required

### Security Configuration Template

```yaml
services:
  service_name:
    image: alpine:3.18 # Always specify exact version

    # Security: Non-root user
    user: "65534:65534" # nobody user

    # Security: Read-only root filesystem
    read_only: true
    tmpfs:
      - /tmp:rw,noexec,nosuid,nodev,size=100m
      - /var/run:rw,noexec,nosuid,nodev,size=50m

    # Security: Linux capabilities
    cap_drop:
      - ALL
    cap_add:
      - SETUID # Only if needed
      - SETGID # Only if needed
      - NET_BIND_SERVICE # Only for services binding to <1024

    # Security: Additional protections
    security_opt:
      - no-new-privileges:true

    # Resource limits (always required)
    deploy:
      resources:
        limits:
          memory: 512M
          cpus: "1.0"
          pids: 100
        reservations:
          memory: 256M
          cpus: "0.5"

    # Health check (always required)
    healthcheck:
      test:
        [
          "CMD",
          "wget",
          "--quiet",
          "--tries=1",
          "--spider",
          "http://localhost:8080/health",
        ]
      interval: 30s
      timeout: 10s
      retries: 3
      start_period: 40s
```

### Current Services Architecture

#### Vaultwarden Application

```yaml
vaultwarden:
  image: vaultwarden/server:1.30.1
  container_name: vaultwarden
  environment:
    - DOMAIN=${DOMAIN}
    - ADMIN_TOKEN=${ADMIN_TOKEN}
    - DATABASE_URL=sqlite:///data/db.sqlite3
    - WEBSOCKET_ENABLED=true
    - LOG_LEVEL=info
  volumes:
    - vw_data:/data
  networks:
    - vaultwarden_net
  ports:
    - "8080:80" # Internal only
```

#### Nginx Proxy

```yaml
nginx-proxy:
  image: nginxproxy/nginx-proxy:1.4
  container_name: nginx-proxy
  volumes:
    - /var/run/docker.sock:/tmp/docker.sock:ro
    - nginx_certs:/etc/nginx/certs:ro
    - nginx_vhost:/etc/nginx/vhost.d
    - nginx_html:/usr/share/nginx/html
  ports:
    - "80:80"
    - "443:443"
```

#### Backup Service

```yaml
backup-service:
  build:
    context: .
    dockerfile: Dockerfile.backup
  container_name: vw_backup
  environment:
    - S3_BUCKET=${S3_BUCKET}
    - BACKUP_ENCRYPTION_KEY=${BACKUP_ENCRYPTION_KEY}
  volumes:
    - vw_data:/source:ro
    - backup_logs:/var/log
```

### Network Configuration

```yaml
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
```

### Volume Management

- **Application Data**: Named volume with backup procedures
- **Logs**: Separate volume with rotation
- **Certificates**: Named volume for SSL certs
- **Temporary Files**: tmpfs mounts for security

### Environment-Specific Configurations

- **Development**: Relaxed security, local volumes, debug logging
- **Staging**: Production-like security, test certificates
- **Production**: Full security, encrypted volumes, audit logging

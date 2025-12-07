# Deployment Plan - Hetzner Cloud + Kamal 2

Step-by-step guide for deploying NZ Tech Events to Hetzner Cloud using Kamal 2 (Rails' default deployment tool).

---

## Overview

| Component | Choice | Cost |
|-----------|--------|------|
| Server | Hetzner Cloud CX22 | ~€5/month |
| Registry | GitHub Container Registry | Free |
| SSL | Let's Encrypt (via Traefik) | Free |
| Domain | techevents.co.nz | ~$25/year |

**Total**: ~€7/month (~$12 NZD/month)

---

## Prerequisites Checklist

Before starting deployment:

- [ ] Rails app runs locally without errors
- [ ] All tests pass (if any)
- [ ] Git repository initialized
- [ ] GitHub account (for container registry)
- [ ] Hetzner Cloud account created
- [ ] Domain name purchased
- [ ] Docker installed locally (`docker --version`)
- [ ] Kamal installed (`gem install kamal` or in Gemfile)

---

## PHASE 1: Hetzner Server Setup

### Step 1.1: Create Hetzner Cloud Account

1. Go to https://console.hetzner.cloud
2. Create account and verify email
3. Create a new project: "NZ Tech Events"

**Checklist:**
- [ ] Hetzner account created
- [ ] Project created

---

### Step 1.2: Generate SSH Key (if needed)

```bash
# Check if you have an SSH key
ls ~/.ssh/id_ed25519.pub

# If not, generate one
ssh-keygen -t ed25519 -C "your-email@example.com"
```

**Checklist:**
- [ ] SSH key exists at `~/.ssh/id_ed25519.pub`

---

### Step 1.3: Create Server

In Hetzner Cloud Console:

1. Click "Add Server"
2. **Location**: Helsinki or Falkenstein (EU) - closest to NZ users via CDN
3. **Image**: Ubuntu 24.04
4. **Type**: CX22 (2 vCPU, 4GB RAM, 40GB SSD)
5. **SSH Keys**: Add your public key
6. **Name**: `tech-events-web`
7. Click "Create & Buy Now"

Note the server's **IP address** (e.g., `123.45.67.89`)

**Checklist:**
- [ ] Server created
- [ ] IP address noted: `_______________`

---

### Step 1.4: Configure DNS

In your domain registrar (e.g., Namecheap, Cloudflare):

```
Type    Name    Value               TTL
A       @       123.45.67.89        3600
A       www     123.45.67.89        3600
```

Wait for DNS propagation (can take up to 48 hours, usually minutes).

**Verify:**
```bash
dig +short techevents.co.nz
# Should return your server IP
```

**Checklist:**
- [ ] A record for `@` points to server IP
- [ ] A record for `www` points to server IP
- [ ] DNS propagated (dig returns correct IP)

---

## PHASE 2: GitHub Container Registry Setup

### Step 2.1: Create GitHub Personal Access Token

1. Go to GitHub → Settings → Developer settings → Personal access tokens → Tokens (classic)
2. Click "Generate new token (classic)"
3. **Note**: "Kamal deployment"
4. **Expiration**: 90 days (or longer)
5. **Scopes**: Select `write:packages` and `read:packages`
6. Click "Generate token"
7. **Copy the token immediately** (you won't see it again)

**Checklist:**
- [ ] Token generated with `write:packages` scope
- [ ] Token copied and saved securely

---

### Step 2.2: Test Docker Login

```bash
echo YOUR_GITHUB_TOKEN | docker login ghcr.io -u YOUR_GITHUB_USERNAME --password-stdin
# Should output: Login Succeeded
```

**Checklist:**
- [ ] Docker login to ghcr.io successful

---

## PHASE 3: Application Preparation

### Step 3.1: Create Dockerfile

**File: `Dockerfile`**
```dockerfile
# syntax=docker/dockerfile:1
ARG RUBY_VERSION=3.3.0
FROM ruby:$RUBY_VERSION-slim AS base

WORKDIR /rails

# Set production environment
ENV RAILS_ENV="production" \
    BUNDLE_DEPLOYMENT="1" \
    BUNDLE_PATH="/usr/local/bundle" \
    BUNDLE_WITHOUT="development:test"

# Install base packages
RUN apt-get update -qq && \
    apt-get install --no-install-recommends -y \
    curl \
    libsqlite3-0 \
    && rm -rf /var/lib/apt/lists /var/cache/apt/archives

# Build stage
FROM base AS build

RUN apt-get update -qq && \
    apt-get install --no-install-recommends -y \
    build-essential \
    git \
    pkg-config \
    libsqlite3-dev \
    && rm -rf /var/lib/apt/lists /var/cache/apt/archives

# Install gems
COPY Gemfile Gemfile.lock ./
RUN bundle install && \
    rm -rf ~/.bundle/ "${BUNDLE_PATH}"/ruby/*/cache "${BUNDLE_PATH}"/ruby/*/bundler/gems/*/.git

# Copy application code
COPY . .

# Precompile assets (no Node.js needed!)
RUN SECRET_KEY_BASE_DUMMY=1 ./bin/rails assets:precompile

# Final stage
FROM base

# Copy built artifacts
COPY --from=build /usr/local/bundle /usr/local/bundle
COPY --from=build /rails /rails

# Create non-root user
RUN groupadd --system --gid 1000 rails && \
    useradd rails --uid 1000 --gid 1000 --create-home --shell /bin/bash && \
    chown -R rails:rails db log storage tmp
USER 1000:1000

# Entrypoint prepares database
ENTRYPOINT ["/rails/bin/docker-entrypoint"]

EXPOSE 3000
CMD ["./bin/rails", "server", "-b", "0.0.0.0"]
```

**Checklist:**
- [ ] Dockerfile created
- [ ] No Node.js in Dockerfile (confirms no-build)

---

### Step 3.2: Create Docker Entrypoint

**File: `bin/docker-entrypoint`**
```bash
#!/bin/bash -e

# Prepare database if needed
if [ "${RAILS_ENV}" = "production" ]; then
  ./bin/rails db:prepare
fi

exec "${@}"
```

Make it executable:
```bash
chmod +x bin/docker-entrypoint
```

**Checklist:**
- [ ] docker-entrypoint created
- [ ] Made executable

---

### Step 3.3: Create .dockerignore

**File: `.dockerignore`**
```
# Git
.git
.gitignore

# Logs
log/*

# Temp files
tmp/*

# Storage (will be mounted as volume)
storage/*

# Test files
test/
spec/

# Documentation
*.md
!README.md

# IDE
.idea/
.vscode/

# OS
.DS_Store

# Deployment secrets
.kamal/
.env*

# Development databases
*.sqlite3
```

**Checklist:**
- [ ] .dockerignore created

---

### Step 3.4: Test Docker Build Locally

```bash
docker build -t tech-events-test .
# Should complete without errors

docker run --rm -e SECRET_KEY_BASE=test123 tech-events-test bin/rails -v
# Should output Rails version
```

**Checklist:**
- [ ] Docker build succeeds
- [ ] No Node.js errors during build

---

## PHASE 4: Kamal Configuration

### Step 4.1: Initialize Kamal

```bash
# If kamal not in Gemfile, add it
bundle add kamal

# Initialize Kamal
kamal init
```

This creates:
- `config/deploy.yml` - Main configuration
- `.kamal/secrets` - Secrets file (gitignored)

**Checklist:**
- [ ] Kamal initialized
- [ ] deploy.yml created

---

### Step 4.2: Configure deploy.yml

**File: `config/deploy.yml`**
```yaml
# Service name (used in Docker image name)
service: tech-events

# Docker image location
image: ghcr.io/YOUR_GITHUB_USERNAME/tech-events

# Deploy to these servers
servers:
  web:
    hosts:
      - YOUR_SERVER_IP  # e.g., 123.45.67.89
    labels:
      traefik.http.routers.tech-events.rule: Host(`techevents.co.nz`) || Host(`www.techevents.co.nz`)
      traefik.http.routers.tech-events.tls: true
      traefik.http.routers.tech-events.tls.certresolver: letsencrypt
      traefik.http.routers.tech-events.entrypoints: websecure
      # Redirect www to non-www
      traefik.http.middlewares.www-redirect.redirectregex.regex: ^https://www\.(.*)
      traefik.http.middlewares.www-redirect.redirectregex.replacement: https://$${1}
      traefik.http.routers.tech-events.middlewares: www-redirect

# Docker registry
registry:
  server: ghcr.io
  username: YOUR_GITHUB_USERNAME
  password:
    - KAMAL_REGISTRY_PASSWORD

# Environment variables
env:
  clear:
    RAILS_ENV: production
    RAILS_LOG_TO_STDOUT: "1"
    RAILS_SERVE_STATIC_FILES: "1"
  secret:
    - RAILS_MASTER_KEY
    - SECRET_KEY_BASE
    - GOOGLE_CLIENT_ID
    - GOOGLE_CLIENT_SECRET

# SQLite volumes (persist data!)
volumes:
  - "tech_events_storage:/rails/storage"

# Health check
healthcheck:
  path: /up
  port: 3000
  max_attempts: 10
  interval: 20s

# Traefik for SSL/routing
traefik:
  options:
    publish:
      - "443:443"
      - "80:80"
    volume:
      - "/letsencrypt:/letsencrypt"
  args:
    entryPoints.web.address: ":80"
    entryPoints.websecure.address: ":443"
    entryPoints.web.http.redirections.entryPoint.to: websecure
    entryPoints.web.http.redirections.entryPoint.scheme: https
    certificatesResolvers.letsencrypt.acme.email: "your-email@example.com"
    certificatesResolvers.letsencrypt.acme.storage: "/letsencrypt/acme.json"
    certificatesResolvers.letsencrypt.acme.httpchallenge: true
    certificatesResolvers.letsencrypt.acme.httpchallenge.entrypoint: web

# Build configuration
builder:
  multiarch: false  # Set to true if building on ARM Mac for AMD64 server

# SSH configuration
ssh:
  user: root
```

**Replace:**
- `YOUR_GITHUB_USERNAME` with your GitHub username
- `YOUR_SERVER_IP` with your Hetzner server IP
- `your-email@example.com` with your email (for Let's Encrypt)

**Checklist:**
- [ ] deploy.yml configured
- [ ] GitHub username set
- [ ] Server IP set
- [ ] Email for SSL set

---

### Step 4.3: Configure Secrets

**File: `.kamal/secrets`**
```bash
# GitHub Container Registry token
KAMAL_REGISTRY_PASSWORD=ghp_your_github_token_here

# Rails secrets
RAILS_MASTER_KEY=your_master_key_here
SECRET_KEY_BASE=your_secret_key_base_here

# Google OAuth (optional - leave blank if not using)
GOOGLE_CLIENT_ID=your_client_id.apps.googleusercontent.com
GOOGLE_CLIENT_SECRET=your_client_secret
```

Get your `RAILS_MASTER_KEY`:
```bash
cat config/master.key
```

Generate `SECRET_KEY_BASE`:
```bash
bin/rails secret
```

**Important**: Ensure `.kamal/` is in `.gitignore`!

**Checklist:**
- [ ] KAMAL_REGISTRY_PASSWORD set (GitHub token)
- [ ] RAILS_MASTER_KEY set (from config/master.key)
- [ ] SECRET_KEY_BASE set (generated with rails secret)
- [ ] .kamal/ in .gitignore

---

## PHASE 5: First Deployment

### Step 5.1: Setup Server

This installs Docker and configures the server:

```bash
kamal setup
```

This will:
- SSH into your server
- Install Docker
- Start Traefik (reverse proxy)
- Configure SSL certificates

**Checklist:**
- [ ] `kamal setup` completed without errors

---

### Step 5.2: Deploy Application

```bash
kamal deploy
```

This will:
- Build Docker image locally
- Push to GitHub Container Registry
- Pull image on server
- Start the application
- Configure health checks

**Checklist:**
- [ ] `kamal deploy` completed
- [ ] No errors during deployment

---

### Step 5.3: Verify Deployment

```bash
# Check app is running
kamal app details

# Check logs
kamal logs

# Visit the site
open https://techevents.co.nz
```

**Checklist:**
- [ ] App details show "running"
- [ ] No errors in logs
- [ ] Site loads in browser
- [ ] SSL certificate working (green padlock)

---

### Step 5.4: Run Database Seeds (Optional)

```bash
kamal app exec 'bin/rails db:seed'
```

**Checklist:**
- [ ] Seeds ran (if desired)
- [ ] Sample events visible on site

---

## PHASE 6: Google OAuth Setup (Optional)

### Step 6.1: Create Google Cloud Project

1. Go to https://console.cloud.google.com
2. Create new project: "NZ Tech Events"
3. Enable "Google+ API" (or Google Identity)
4. Go to "Credentials" → "Create Credentials" → "OAuth client ID"
5. Configure consent screen:
   - App name: "NZ Tech Events"
   - User support email: your email
   - Authorized domains: `techevents.co.nz`
6. Create OAuth client:
   - Application type: "Web application"
   - Authorized redirect URIs: `https://techevents.co.nz/auth/google_oauth2/callback`
7. Copy Client ID and Client Secret

**Checklist:**
- [ ] Google Cloud project created
- [ ] OAuth consent screen configured
- [ ] OAuth credentials created
- [ ] Client ID and Secret copied

---

### Step 6.2: Update Secrets and Redeploy

Update `.kamal/secrets` with Google credentials, then:

```bash
kamal env push
kamal app boot
```

**Checklist:**
- [ ] Google credentials in secrets
- [ ] App redeployed
- [ ] Google login works

---

## Ongoing Maintenance

### Deploy Updates

```bash
# After making changes
git add .
git commit -m "Your changes"
kamal deploy
```

### View Logs

```bash
kamal logs -f          # Follow logs
kamal logs --since 1h  # Last hour
```

### Rails Console

```bash
kamal app exec -i 'bin/rails console'
```

### Database Backup

```bash
# Download database file
kamal app exec 'cat storage/production.sqlite3' > backup_$(date +%Y%m%d).sqlite3

# Or SSH and copy
scp root@YOUR_SERVER_IP:/var/lib/docker/volumes/tech_events_storage/_data/production.sqlite3 ./backup.sqlite3
```

### Rollback

```bash
kamal rollback
```

### Restart App

```bash
kamal app boot
```

---

## Troubleshooting

### SSL Certificate Issues

```bash
# Check Traefik logs
kamal traefik logs

# Restart Traefik
kamal traefik reboot

# Verify DNS
dig +short techevents.co.nz
```

### App Won't Start

```bash
# Check container logs
kamal logs

# Check health endpoint manually
kamal app exec 'curl localhost:3000/up'

# Check Rails logs
kamal app exec 'cat log/production.log'
```

### Database Issues

```bash
# Run migrations
kamal app exec 'bin/rails db:migrate'

# Reset database (CAUTION: deletes all data!)
kamal app exec 'bin/rails db:reset'
```

### Out of Disk Space

```bash
# SSH to server
ssh root@YOUR_SERVER_IP

# Clean Docker
docker system prune -a

# Check disk
df -h
```

---

## Security Checklist

- [ ] SSH key authentication only (password auth disabled)
- [ ] Firewall allows only ports 22, 80, 443
- [ ] SSL/TLS enabled (Let's Encrypt)
- [ ] RAILS_MASTER_KEY kept secure
- [ ] .kamal/secrets not in git
- [ ] Regular database backups

---

## Cost Summary

| Item | Cost |
|------|------|
| Hetzner CX22 | €4.51/month |
| Domain (.co.nz) | ~$25/year |
| SSL (Let's Encrypt) | Free |
| GitHub Registry | Free |
| **Total** | **~$9 NZD/month** |

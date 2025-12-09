# Deployment Plan - Hetzner Cloud + Kamal 2

Step-by-step guide for deploying NZ Tech Events to Hetzner Cloud using Kamal 2 (Rails' default deployment tool).

**Deploy from**: Local machine (no GitHub Actions or CI/CD required)

---

## Overview

| Component | Choice | Cost |
|-----------|--------|------|
| Server | Hetzner Cloud CX22 | ~€5/month |
| Registry | Local registry on server | Free |
| SSL | Let's Encrypt (via Traefik) | Free |
| Domain | techevents.co.nz | ~$25/year |

**Total**: ~€7/month (~$12 NZD/month)

---

## Prerequisites Checklist

Before starting deployment:

- [x] Rails app runs locally without errors
- [x] All tests pass (if any)
- [x] Git repository initialized
- [x] Hetzner Cloud account created
- [x] Domain name purchased
- [x] Docker installed locally (`docker --version`)
- [x] Kamal installed (`gem install kamal` or in Gemfile)

---

## PHASE 1: Hetzner Server Setup

### Step 1.1: Create Hetzner Cloud Account

1. Go to https://console.hetzner.cloud
2. Create account and verify email
3. Create a new project: "NZ Tech Events"

**Checklist:**
- [x] Hetzner account created
- [x] Project created

---

### Step 1.2: Generate SSH Key (if needed)

```bash
# Check if you have an SSH key
ls ~/.ssh/id_ed25519.pub

# If not, generate one
ssh-keygen -t ed25519 -C "rowan.savage@gmail.com"
```

**Checklist:**
- [x] SSH key exists at `~/.ssh/id_ed25519.pub`

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

Note the server's **IP address** (e.g., `77.42.38.51`)

**Checklist:**
- [x] Server created
- [x] IP address noted: `77.42.38.51`

---

### Step 1.4: Configure DNS

In your domain registrar (e.g., Namecheap, Cloudflare):

```
Type    Name    Value               TTL
A       @       77.42.38.51        3600
A       www     77.42.38.51        3600
```

Wait for DNS propagation (can take up to 48 hours, usually minutes).

**Verify:**
```bash
dig +short techevents.co.nz
# Should return your server IP
```

**Checklist:**
- [x] A record for `@` points to server IP
- [x] A record for `www` points to server IP
- [x] DNS propagated (dig returns correct IP)

---

## PHASE 2: Local Registry Setup

Kamal will automatically set up a local Docker registry on your server. No external registry (like GitHub or Docker Hub) is needed.

### Step 2.1: Verify Docker Works Locally

```bash
docker --version
# Should output Docker version
```

**Checklist:**
- [x] Docker installed and running locally

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
- [x] Dockerfile created
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
- [x] docker-entrypoint created
- [x] Made executable

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
- [x] .dockerignore created

---

### Step 3.4: Test Docker Build Locally

```bash
docker build -t tech-events-test .
# Should complete without errors

docker run --rm -e SECRET_KEY_BASE=test123 tech-events-test bin/rails -v
# Should output Rails version
```

**Checklist:**
- [x] Docker build succeeds

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
- [x] Kamal initialized
- [x] deploy.yml created

---

### Step 4.2: Configure deploy.yml

**File: `config/deploy.yml`**
```yaml
# Service name (used in Docker image name)
service: tech-events

# Docker image name
image: tech-events

# Deploy to these servers
servers:
  web:
    hosts:
      - 77.42.38.51

# Enable SSL via Let's Encrypt (Kamal 2 built-in proxy)
# Requires config.assume_ssl and config.force_ssl in production.rb
proxy:
  ssl: true
  host: techevents.co.nz
  app_port: 3000

# Use Kamal's built-in local registry on the server
registry:
  server: localhost:5555

# Environment variables
env:
  secret:
    - RAILS_MASTER_KEY
    - SECRET_KEY_BASE
  clear:
    SOLID_QUEUE_IN_PUMA: true
    RAILS_LOG_TO_STDOUT: "1"

# Aliases for common commands
aliases:
  console: app exec --interactive --reuse "bin/rails console"
  shell: app exec --interactive --reuse "bash"
  logs: app logs -f
  dbc: app exec --interactive --reuse "bin/rails dbconsole --include-password"

# SQLite volumes (persist data!)
volumes:
  - "tech_events_storage:/rails/storage"

# Bridge assets between versions
asset_path: /rails/public/assets

# Build for AMD64 (Hetzner servers)
builder:
  arch: amd64

# SSH as root
ssh:
  user: root
```

**Also enable SSL in production.rb** (uncomment these lines):
```ruby
config.assume_ssl = true
config.force_ssl = true
config.ssl_options = { redirect: { exclude: ->(request) { request.path == "/up" } } }
```

**Checklist:**
- [x] deploy.yml configured
- [x] Server IP set (77.42.38.51)
- [x] SSL enabled in production.rb

---

### Step 4.3: Configure Secrets

**File: `.kamal/secrets`**
```bash
# Read master key from file (don't hardcode!)
RAILS_MASTER_KEY=$(cat config/master.key)

# Generate with: bin/rails secret
SECRET_KEY_BASE=your_secret_key_base_here
```

Get your `SECRET_KEY_BASE`:
```bash
bin/rails secret
# Copy the output and paste it in .kamal/secrets
```

**Important**: Ensure `.kamal/` is in `.gitignore`!

**Checklist:**
- [x] RAILS_MASTER_KEY reads from config/master.key
- [x] SECRET_KEY_BASE set (generated with rails secret)
- [x] .kamal/ in .gitignore

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
- Configure SSL certificates

**Checklist:**
- [ ] `kamal setup` completed without errors

---

### Step 5.2: Deploy Application

```bash
kamal deploy
```

This will:
- Build Docker image locally on your Mac
- Push image directly to the server via SSH
- Start the application container
- Configure health checks

**Note**: First deploy may take a few minutes as it builds the image and transfers it to the server.

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

### Deploy Updates (from your local machine)

```bash
# After making changes locally
git add .
git commit -m "Your changes"
kamal deploy

# Kamal builds locally and pushes to server - no CI/CD needed
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
| Docker Registry | Free (local on server) |
| **Total** | **~$9 NZD/month** |

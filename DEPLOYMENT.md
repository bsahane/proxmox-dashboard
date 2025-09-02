# 🚀 Deployment Guide

## Quick Start Options

### 🟢 **Development Mode (Recommended for testing)**
```bash
npm run dev
```
- No container required
- Live reload
- Debug mode enabled
- Access at http://localhost:3000

### 🐳 **Container Deployment**

#### Option 1: Quick Deploy (No prompts)
```bash
./quick-deploy.sh
```

#### Option 2: Interactive Deploy
```bash
./deploy.sh
```

## Container Setup

### 🍎 **macOS Setup**

**If using Podman:**
```bash
# Install Podman (if not installed)
brew install podman

# Setup Podman machine
./setup-podman.sh

# Deploy
./deploy.sh
```

**If using Docker:**
```bash
# Install Docker Desktop for Mac (if not installed)
# Then run:
./deploy.sh
```

### 🐧 **Linux Setup**

**Podman:**
```bash
# Install Podman
sudo apt install podman  # Ubuntu/Debian
sudo dnf install podman  # Fedora

# Deploy
./deploy.sh
```

**Docker:**
```bash
# Install Docker
curl -fsSL https://get.docker.com -o get-docker.sh
sh get-docker.sh

# Deploy
./deploy.sh
```

## Configuration

### Environment Files

Create your configuration based on your setup:

**For Local Development (IP-based):**
```bash
cp .env.local.example .env.local
```

**For Production (Domain-based):**
```bash
cp .env.production.example .env
```

### Manual Configuration

Edit your environment file:

```env
# Server Configuration
PROXMOX_HOST=https://your-server:8006
GUACAMOLE_HOST=http://your-guacamole:8080

# SSL Configuration
NODE_TLS_REJECT_UNAUTHORIZED=0  # For self-signed certs
# NODE_TLS_REJECT_UNAUTHORIZED=1  # For valid domain certs

# Optional Settings
PROXMOX_API_TIMEOUT=30000
DASHBOARD_REFRESH_INTERVAL=30
DEBUG_LOGGING=false
```

## Deployment Scripts

### 📋 **Script Overview**

| Script | Purpose | User Input | Time |
|--------|---------|------------|------|
| `npm run dev` | Development mode | None | 30s |
| `./quick-deploy.sh` | Container (auto) | None | 2-3min |
| `./deploy.sh` | Container (interactive) | Yes | 3-5min |
| `./setup-podman.sh` | Podman setup | Minimal | 1-2min |

### 🔧 **Script Details**

#### `./quick-deploy.sh`
- **Purpose**: Fast deployment with smart defaults
- **Ports**: Auto-detects available port (starting from 7070)
- **Config**: Uses defaults, creates .env automatically
- **Best for**: Quick testing, CI/CD, demos

#### `./deploy.sh`
- **Purpose**: Full interactive deployment
- **Ports**: User chooses port with validation
- **Config**: User inputs all URLs
- **Best for**: Production, custom setups

#### `./setup-podman.sh`
- **Purpose**: One-time Podman initialization
- **Actions**: Creates and starts Podman VM
- **Best for**: First-time Podman users on macOS

## Troubleshooting

### 🔴 **Container Issues**

**Podman on macOS:**
```bash
# Check machine status
podman machine list

# Start machine if stopped
podman machine start

# Recreate if corrupted
podman machine rm podman-machine-default
podman machine init
podman machine start
```

**Docker issues:**
```bash
# Check Docker status
docker info

# Restart Docker Desktop (macOS)
# Use system tray icon
```

### 🔴 **Port Issues**

**Port already in use:**
```bash
# Find what's using the port
lsof -i :7070

# Kill the process
kill $(lsof -t -i:7070)

# Or use different port
./deploy.sh  # Choose different port when prompted
```

### 🔴 **SSL Issues**

**Self-signed certificate errors:**
```env
NODE_TLS_REJECT_UNAUTHORIZED=0
```

**Domain certificate issues:**
```env
NODE_TLS_REJECT_UNAUTHORIZED=1
```

### 🔴 **Permission Issues**

**macOS/Linux script permissions:**
```bash
chmod +x *.sh
```

**Container permissions:**
```bash
# Podman rootless issues
podman unshare chown -R 1001:1001 ./logs

# Docker permission issues
sudo usermod -aG docker $USER
newgrp docker
```

## Production Deployment

### 🏢 **Enterprise Setup**

1. **Use domain-based URLs:**
```env
PROXMOX_HOST=https://pve.company.com:8006
GUACAMOLE_HOST=https://remote.company.com
NODE_TLS_REJECT_UNAUTHORIZED=1
```

2. **Enable proper SSL:**
- Valid SSL certificates on both servers
- Firewall rules for dashboard port
- Load balancer if needed

3. **Security hardening:**
- Non-root container user
- Resource limits
- Network isolation
- Regular updates

### ☁️ **Cloud Deployment**

**Docker Compose:**
```bash
# Edit docker-compose.yml with your settings
docker-compose up -d
```

**Kubernetes:**
```bash
# Create ConfigMap from .env
kubectl create configmap proxmox-config --from-env-file=.env

# Deploy (create deployment.yaml first)
kubectl apply -f deployment.yaml
```

## Quick Reference

### 🚀 **Common Commands**

```bash
# Development
npm run dev                    # Start dev server
npm run build                  # Build for production
npm start                      # Start production server

# Container Management
./quick-deploy.sh              # Quick container deploy
./deploy.sh                    # Interactive deploy
podman ps                      # List containers
podman logs proxmox-dashboard  # View logs
podman stop proxmox-dashboard  # Stop container

# Configuration
cp .env.example .env.local     # Development config
cp .env.production.example .env # Production config
```

### 📊 **Default Settings**

| Setting | Development | Production |
|---------|-------------|------------|
| Port | 3000 | 7070 |
| SSL Verify | Disabled | Enabled |
| Refresh | 30s | 60s |
| Timeout | 30s | 60s |
| Debug | Enabled | Disabled |

### 🌐 **Access URLs**

- **Development**: http://localhost:3000
- **Container**: http://localhost:7070 (or chosen port)
- **Network**: http://your-ip:port

## Support

For issues:
1. Check this troubleshooting guide
2. Review container logs: `podman logs proxmox-dashboard`
3. Verify environment configuration
4. Test Proxmox API access manually
5. Check GitHub issues or create new one

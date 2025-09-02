# Fix Docker Deployment

## Current Docker Issues & Solutions

### Issue: Missing Dependencies in Container
The container build fails because all dependencies are not properly installed.

### Solution: Updated deployment script

Create a new deployment script that handles all dependencies:

```bash
#!/bin/bash

echo "🐳 Fixed Docker Deployment for Proxmox Dashboard"
echo ""

# Architecture detection
ARCH=$(uname -m)
case $ARCH in
    x86_64) DOCKER_ARCH="amd64" ;;
    aarch64|arm64) DOCKER_ARCH="arm64" ;;
    *) echo "❌ Unsupported architecture: $ARCH" && exit 1 ;;
esac

echo "🔍 Detected architecture: $ARCH -> $DOCKER_ARCH"

# Container runtime detection
if command -v podman >/dev/null 2>&1; then
    CONTAINER_CMD="podman"
elif command -v docker >/dev/null 2>&1; then
    CONTAINER_CMD="docker"
else
    echo "❌ Neither Docker nor Podman found!"
    exit 1
fi

echo "🐳 Using container runtime: $CONTAINER_CMD"

# Port configuration
read -p "Enter port for dashboard [default: 7070]: " PORT
PORT=${PORT:-7070}

# Proxmox configuration
read -p "Enter Proxmox server URL [default: https://192.168.50.7:8006]: " PROXMOX_HOST
PROXMOX_HOST=${PROXMOX_HOST:-https://192.168.50.7:8006}

# Guacamole configuration  
read -p "Enter Guacamole server URL [default: http://192.168.50.183:8080]: " GUACAMOLE_HOST
GUACAMOLE_HOST=${GUACAMOLE_HOST:-http://192.168.50.183:8080}

# Create .env file
cat > .env << EOF
PROXMOX_HOST=$PROXMOX_HOST
GUACAMOLE_HOST=$GUACAMOLE_HOST
NODE_TLS_REJECT_UNAUTHORIZED=0
NEXT_TELEMETRY_DISABLED=1
NODE_ENV=production
EOF

echo "✅ Created .env configuration"

# Build container with proper dependency installation
echo "🔨 Building container with all dependencies..."

$CONTAINER_CMD build \
    --platform linux/$DOCKER_ARCH \
    --build-arg NODE_ENV=production \
    --tag proxmox-dashboard:latest \
    --file Containerfile \
    . || {
    echo "❌ Container build failed!"
    echo "🔧 Trying alternative build approach..."
    
    # Alternative: Build without cache
    $CONTAINER_CMD build \
        --no-cache \
        --platform linux/$DOCKER_ARCH \
        --tag proxmox-dashboard:latest \
        --file Containerfile \
        . || {
        echo "❌ Both build attempts failed!"
        echo "🔍 Please check logs above for specific errors"
        exit 1
    }
}

echo "✅ Container built successfully!"

# Stop existing container
$CONTAINER_CMD stop proxmox-dashboard 2>/dev/null || true
$CONTAINER_CMD rm proxmox-dashboard 2>/dev/null || true

# Run container
echo "🚀 Starting Proxmox Dashboard..."
$CONTAINER_CMD run -d \
    --name proxmox-dashboard \
    --restart unless-stopped \
    -p $PORT:3000 \
    --env-file .env \
    proxmox-dashboard:latest

# Check if container is running
sleep 5
if $CONTAINER_CMD ps | grep -q proxmox-dashboard; then
    echo ""
    echo "🎉 SUCCESS! Proxmox Dashboard is running!"
    echo ""
    echo "📊 Access your dashboard:"
    echo "   🌐 URL: http://$(hostname -I | awk '{print $1}'):$PORT"
    echo "   🌐 Local: http://localhost:$PORT"
    echo ""
    echo "🔧 Management commands:"
    echo "   📋 Status: $CONTAINER_CMD ps | grep proxmox-dashboard"
    echo "   📝 Logs: $CONTAINER_CMD logs -f proxmox-dashboard"
    echo "   🔄 Restart: $CONTAINER_CMD restart proxmox-dashboard"
    echo "   🛑 Stop: $CONTAINER_CMD stop proxmox-dashboard"
else
    echo "❌ Container failed to start!"
    echo "📝 Check logs: $CONTAINER_CMD logs proxmox-dashboard"
fi
```

### Alternative: Use Docker Compose

Create `docker-compose.yml`:

```yaml
version: '3.8'

services:
  proxmox-dashboard:
    build: .
    ports:
      - "${PORT:-7070}:3000"
    environment:
      - NODE_TLS_REJECT_UNAUTHORIZED=0
      - NEXT_TELEMETRY_DISABLED=1
      - NODE_ENV=production
      - PROXMOX_HOST=${PROXMOX_HOST:-https://192.168.50.7:8006}
      - GUACAMOLE_HOST=${GUACAMOLE_HOST:-http://192.168.50.183:8080}
    restart: unless-stopped
    container_name: proxmox-dashboard
```

Then run:
```bash
docker-compose up -d
```

## Quick Fix Commands

### For immediate Docker fix:
```bash
# Rebuild with no cache
docker build --no-cache -t proxmox-dashboard .

# Run with proper environment
docker run -d \
  --name proxmox-dashboard \
  --restart unless-stopped \
  -p 7070:3000 \
  -e NODE_TLS_REJECT_UNAUTHORIZED=0 \
  -e PROXMOX_HOST=https://192.168.50.7:8006 \
  -e GUACAMOLE_HOST=http://192.168.50.183:8080 \
  proxmox-dashboard
```

#!/bin/bash

# Quick Deploy Script - No prompts, uses defaults
# For fast deployment with sensible defaults

set -e

# Colors
GREEN='\033[0;32m'
BLUE='\033[0;34m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
NC='\033[0m'

# Default values
DEFAULT_PORT=7070
DEFAULT_PROXMOX_HOST="https://192.168.50.7:8006"
DEFAULT_GUACAMOLE_HOST="http://192.168.50.183:8080"
CONTAINER_NAME="proxmox-dashboard"
IMAGE_NAME="proxmox-dashboard"

echo -e "${BLUE}"
echo "🚀 Proxmox Dashboard - Quick Deploy"
echo "=================================="
echo -e "${NC}"

# Detect container runtime (prioritize Docker on macOS)
if [[ "$OSTYPE" == "darwin"* ]] && command -v docker &> /dev/null; then
    RUNTIME="docker"
elif command -v podman &> /dev/null; then
    RUNTIME="podman"
elif command -v docker &> /dev/null; then
    RUNTIME="docker"
else
    echo -e "${RED}❌ No container runtime found! Please install Docker or Podman.${NC}"
    exit 1
fi

echo -e "${GREEN}✅ Using $RUNTIME runtime${NC}"

# Check if port is available
check_port() {
    local port=$1
    if lsof -Pi :$port -sTCP:LISTEN -t >/dev/null 2>&1; then
        return 1
    else
        return 0
    fi
}

# Find available port starting from default
PORT=$DEFAULT_PORT
while ! check_port "$PORT"; do
    PORT=$((PORT + 1))
done

echo -e "${GREEN}✅ Using port: $PORT${NC}"

# Stop existing container
if $RUNTIME container exists $CONTAINER_NAME 2>/dev/null; then
    echo -e "${YELLOW}⚠️  Stopping existing container...${NC}"
    $RUNTIME stop $CONTAINER_NAME 2>/dev/null || true
    $RUNTIME rm $CONTAINER_NAME 2>/dev/null || true
fi

# Create .env file
echo -e "${GREEN}✅ Creating configuration...${NC}"
cat > .env << EOF
# Proxmox Dashboard Configuration - Quick Deploy
PROXMOX_HOST=$DEFAULT_PROXMOX_HOST
GUACAMOLE_HOST=$DEFAULT_GUACAMOLE_HOST
NODE_TLS_REJECT_UNAUTHORIZED=0
NEXT_TELEMETRY_DISABLED=1
NODE_ENV=production
PROXMOX_API_TIMEOUT=30000
DASHBOARD_REFRESH_INTERVAL=30
DEBUG_LOGGING=false
EOF

# Build container
echo -e "${GREEN}✅ Building container...${NC}"
$RUNTIME build --tag $IMAGE_NAME:latest --file Containerfile . || {
    echo -e "${RED}❌ Container build failed${NC}"
    exit 1
}

# Run container
echo -e "${GREEN}✅ Starting container...${NC}"
$RUNTIME run -d \
    --name $CONTAINER_NAME \
    --restart unless-stopped \
    -p $PORT:3000 \
    --env-file .env \
    $IMAGE_NAME:latest || {
    echo -e "${RED}❌ Container start failed${NC}"
    exit 1
}

echo -e "${GREEN}"
echo "🎉 Deployment Complete!"
echo "======================="
echo -e "${NC}"
echo -e "${BLUE}🌐 Dashboard URL:${NC} http://localhost:$PORT"

# Try to get network IP
if command -v hostname &> /dev/null; then
    NETWORK_IP=$(hostname -I 2>/dev/null | awk '{print $1}' 2>/dev/null || echo "")
    if [[ -n "$NETWORK_IP" ]]; then
        echo -e "${BLUE}🖥️  Network URL:${NC} http://$NETWORK_IP:$PORT"
    fi
fi

echo ""
echo -e "${GREEN}📊 Container Status:${NC}"
$RUNTIME ps --filter name=$CONTAINER_NAME --format "table {{.Names}}\t{{.Status}}\t{{.Ports}}"
echo ""
echo -e "${YELLOW}💡 Quick Commands:${NC}"
echo -e "   📝 Logs: ${BLUE}$RUNTIME logs -f $CONTAINER_NAME${NC}"
echo -e "   🛑 Stop: ${BLUE}$RUNTIME stop $CONTAINER_NAME${NC}"
echo -e "   🗑️  Remove: ${BLUE}$RUNTIME rm $CONTAINER_NAME${NC}"
echo ""
echo -e "${GREEN}✅ Login with your Proxmox credentials (username@realm format)${NC}"
echo -e "${GREEN}✅ Example: root@pam or admin@pve${NC}"

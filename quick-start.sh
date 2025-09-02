#!/bin/bash

# Quick Start Script for Proxmox Dashboard
# One-liner deployment with sensible defaults

set -e

# Colors
GREEN='\033[0;32m'
BLUE='\033[0;34m'
YELLOW='\033[1;33m'
NC='\033[0m'

echo -e "${BLUE}"
echo "🚀 Proxmox Dashboard - Quick Start"
echo "=================================="
echo -e "${NC}"

# Check if deploy.sh exists
if [ ! -f "deploy.sh" ]; then
    echo -e "${YELLOW}⚠️  deploy.sh not found. Downloading...${NC}"
    curl -fsSL https://raw.githubusercontent.com/your-repo/proxmox-dashboard/main/deploy.sh -o deploy.sh
    chmod +x deploy.sh
fi

# Run deployment with default values
echo -e "${GREEN}🔧 Starting deployment with defaults...${NC}"
echo "   📡 Port: 7070"
echo "   🖥️  Proxmox: https://192.168.50.7:8006"
echo "   🎮 Guacamole: http://192.168.50.183:8080"
echo ""

# Create auto-response for deploy.sh
{
    echo ""        # Accept default port
    echo ""        # Accept default Proxmox host
    echo ""        # Accept default Guacamole host
    echo "y"       # Confirm deployment
} | ./deploy.sh

echo -e "${GREEN}"
echo "✅ Quick start completed!"
echo "🌐 Access your dashboard at: http://localhost:7070"
echo -e "${NC}"

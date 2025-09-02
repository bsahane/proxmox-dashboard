#!/bin/bash

# Podman Setup Script for macOS
# This script initializes and starts Podman for container deployment

set -e

# Colors
GREEN='\033[0;32m'
BLUE='\033[0;34m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
NC='\033[0m'

echo -e "${BLUE}"
echo "🐳 Podman Setup for macOS"
echo "========================="
echo -e "${NC}"

# Check if Podman is installed
if ! command -v podman &> /dev/null; then
    echo -e "${RED}❌ Podman not found! Please install it first:${NC}"
    echo -e "${YELLOW}   brew install podman${NC}"
    exit 1
fi

echo -e "${GREEN}✅ Podman found: $(podman --version)${NC}"

# Check if machine exists
if podman machine list | grep -q "podman-machine-default"; then
    echo -e "${GREEN}✅ Podman machine already exists${NC}"
    
    # Check if it's running
    if podman machine list | grep "podman-machine-default" | grep -q "Currently running"; then
        echo -e "${GREEN}✅ Podman machine is already running${NC}"
    else
        echo -e "${YELLOW}⚠️  Starting Podman machine...${NC}"
        podman machine start
        echo -e "${GREEN}✅ Podman machine started${NC}"
    fi
else
    echo -e "${YELLOW}🔧 Initializing Podman machine...${NC}"
    podman machine init
    echo -e "${GREEN}✅ Podman machine initialized${NC}"
    
    echo -e "${YELLOW}🚀 Starting Podman machine...${NC}"
    podman machine start
    echo -e "${GREEN}✅ Podman machine started${NC}"
fi

# Test Podman connection
echo -e "${BLUE}🧪 Testing Podman connection...${NC}"
if podman info >/dev/null 2>&1; then
    echo -e "${GREEN}✅ Podman is working correctly!${NC}"
else
    echo -e "${RED}❌ Podman connection test failed${NC}"
    exit 1
fi

echo -e "${GREEN}"
echo "🎉 Podman Setup Complete!"
echo "========================="
echo -e "${NC}"
echo -e "${BLUE}You can now run:${NC}"
echo -e "  🚀 ./deploy.sh        # Interactive deployment"
echo -e "  ⚡ ./quick-deploy.sh   # One-click deployment"
echo ""
echo -e "${YELLOW}💡 Podman Commands:${NC}"
echo -e "  📊 podman machine list    # Show machine status"
echo -e "  🛑 podman machine stop    # Stop machine"
echo -e "  🚀 podman machine start   # Start machine"

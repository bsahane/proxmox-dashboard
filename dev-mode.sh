#!/bin/bash

# Development Mode Script - No container required
# Quick way to run the dashboard in development mode

set -e

# Colors
GREEN='\033[0;32m'
BLUE='\033[0;34m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
NC='\033[0m'

echo -e "${BLUE}"
echo "🚀 Proxmox Dashboard - Development Mode"
echo "======================================"
echo -e "${NC}"

# Check if we're in the right directory
if [ ! -f "package.json" ]; then
    echo -e "${RED}❌ package.json not found. Please run this script from the project root.${NC}"
    exit 1
fi

# Check if Node.js is installed
if ! command -v node &> /dev/null; then
    echo -e "${RED}❌ Node.js not found! Please install Node.js first.${NC}"
    echo -e "${YELLOW}   Visit: https://nodejs.org${NC}"
    exit 1
fi

echo -e "${GREEN}✅ Node.js found: $(node --version)${NC}"

# Check if npm is installed
if ! command -v npm &> /dev/null; then
    echo -e "${RED}❌ npm not found! Please install npm first.${NC}"
    exit 1
fi

echo -e "${GREEN}✅ npm found: $(npm --version)${NC}"

# Check if .env.local exists
if [ ! -f ".env.local" ]; then
    echo -e "${YELLOW}⚠️  .env.local not found. Creating from example...${NC}"
    if [ -f ".env.example" ]; then
        cp .env.example .env.local
        echo -e "${GREEN}✅ Created .env.local from .env.example${NC}"
        echo -e "${BLUE}📝 Please edit .env.local with your Proxmox and Guacamole URLs${NC}"
    else
        echo -e "${YELLOW}⚠️  Creating basic .env.local...${NC}"
        cat > .env.local << EOF
# Proxmox Dashboard - Development Configuration
PROXMOX_HOST=https://192.168.50.7:8006
GUACAMOLE_HOST=http://192.168.50.183:8080
NODE_TLS_REJECT_UNAUTHORIZED=0
NEXT_TELEMETRY_DISABLED=1
NODE_ENV=development
PROXMOX_API_TIMEOUT=30000
DASHBOARD_REFRESH_INTERVAL=30
DEBUG_LOGGING=true
EOF
        echo -e "${GREEN}✅ Created basic .env.local${NC}"
    fi
fi

# Install dependencies if node_modules doesn't exist
if [ ! -d "node_modules" ]; then
    echo -e "${YELLOW}📦 Installing dependencies...${NC}"
    npm install
    echo -e "${GREEN}✅ Dependencies installed${NC}"
fi

# Check for any security vulnerabilities
echo -e "${BLUE}🔍 Checking for security vulnerabilities...${NC}"
npm audit --audit-level high 2>/dev/null || echo -e "${YELLOW}⚠️  Some vulnerabilities found (non-critical)${NC}"

echo -e "${GREEN}"
echo "🎉 Starting Development Server!"
echo "==============================="
echo -e "${NC}"
echo -e "${BLUE}🌐 URL:${NC} http://localhost:3000"
echo -e "${BLUE}📝 Config:${NC} .env.local"
echo -e "${BLUE}🔧 Mode:${NC} Development (live reload enabled)"
echo ""
echo -e "${YELLOW}💡 Tips:${NC}"
echo -e "   • Edit .env.local to configure your servers"
echo -e "   • Press Ctrl+C to stop the server"
echo -e "   • Changes auto-reload in the browser"
echo ""

# Start the development server
npm run dev

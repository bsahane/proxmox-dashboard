#!/bin/bash

# Test Docker Build Script
# Simple test to validate Docker build process

set -e

# Colors
GREEN='\033[0;32m'
RED='\033[0;31m'
BLUE='\033[0;34m'
NC='\033[0m'

echo -e "${BLUE}🧪 Testing Docker Build Process${NC}"
echo "=================================="

# Check Docker
if ! command -v docker &> /dev/null; then
    echo -e "${RED}❌ Docker not found${NC}"
    exit 1
fi

echo -e "${GREEN}✅ Docker found${NC}"

# Test port check
echo -e "${BLUE}🔍 Testing port checker...${NC}"
if command -v python3 >/dev/null 2>&1; then
    python3 -c "
import socket
try:
    s = socket.socket(socket.AF_INET, socket.SOCK_STREAM)
    s.settimeout(1)
    result = s.connect_ex(('localhost', 7070))
    s.close()
    print('Port 7070 is', 'BUSY' if result == 0 else 'AVAILABLE')
    exit(0 if result != 0 else 1)
except Exception as e:
    print('Port check failed:', e)
    exit(0)
"
else
    echo -e "${RED}❌ Python3 not found for port checking${NC}"
fi

# Test simple Docker build (no dependencies)
echo -e "${BLUE}🐳 Testing basic Docker build...${NC}"
cat > Dockerfile.test << 'EOF'
FROM node:18-alpine
WORKDIR /app
RUN echo '{"name":"test","version":"1.0.0","dependencies":{}}' > package.json
RUN npm install --production
RUN echo "console.log('Build test successful')" > app.js
CMD ["node", "app.js"]
EOF

if docker build -f Dockerfile.test -t proxmox-build-test . >/dev/null 2>&1; then
    echo -e "${GREEN}✅ Basic Docker build works${NC}"
    docker rmi proxmox-build-test >/dev/null 2>&1
else
    echo -e "${RED}❌ Basic Docker build failed${NC}"
fi

# Clean up
rm -f Dockerfile.test

echo -e "${GREEN}🎉 Build test completed${NC}"

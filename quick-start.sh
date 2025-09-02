#!/bin/bash

# Quick Start Script for Proxmox Dashboard
# Handles npm execution with auto-restart and logging

echo "🚀 Proxmox Dashboard Quick Start"
echo "=================================="

# Check if we're in the right directory
if [ ! -f "package.json" ]; then
    echo "❌ Error: package.json not found!"
    echo "Please run this script from the proxmox-dashboard directory"
    exit 1
fi

# Function to choose startup method
choose_method() {
    echo ""
    echo "Choose startup method:"
    echo "1) PM2 Process Manager (Recommended - advanced features)"
    echo "2) Custom Service Script (Auto-restart + logging)"  
    echo "3) Simple Background Process"
    echo "4) Systemd Service (System-level service)"
    
    read -p "Enter choice [1-4]: " choice
    
    case $choice in
        1) start_pm2 ;;
        2) start_service ;;
        3) start_simple ;;
        4) start_systemd ;;
        *) echo "❌ Invalid choice" && exit 1 ;;
    esac
}

# Method 1: PM2
start_pm2() {
    echo "🔄 Setting up PM2..."
    
    # Install PM2 if not available
    if ! command -v pm2 >/dev/null 2>&1; then
        echo "📦 Installing PM2..."
        npm install -g pm2
    fi
    
    # Create log directory
    mkdir -p /var/log/proxmox-dashboard
    
    # Copy PM2 config to current directory if it doesn't exist
    if [ ! -f "ecosystem.config.js" ]; then
        cp pm2-config.js ecosystem.config.js 2>/dev/null || {
            echo "⚠️  PM2 config not found, using basic setup"
            # Create basic PM2 config
            cat > ecosystem.config.js << 'EOF'
module.exports = {
  apps: [{
    name: 'proxmox-dashboard',
    script: 'npm',
    args: 'run dev',
    cwd: process.cwd(),
    env: {
      NODE_TLS_REJECT_UNAUTHORIZED: '0'
    },
    autorestart: true,
    max_restarts: 10,
    min_uptime: '10s',
    restart_delay: 3000
  }]
};
EOF
        }
    fi
    
    # Start with PM2
    pm2 start ecosystem.config.js
    pm2 save
    pm2 startup
    
    echo "✅ PM2 started successfully!"
    echo ""
    echo "📋 PM2 Commands:"
    echo "   pm2 status                 - Check status"
    echo "   pm2 logs proxmox-dashboard - View logs"
    echo "   pm2 restart proxmox-dashboard - Restart"
    echo "   pm2 stop proxmox-dashboard - Stop"
    echo "   pm2 monit                  - Monitor"
}

# Method 2: Custom Service
start_service() {
    echo "🔄 Setting up custom service..."
    
    # Make service script executable
    chmod +x start-service.sh
    
    # Start the service
    ./start-service.sh start
    
    echo "✅ Service started successfully!"
    echo ""
    echo "📋 Service Commands:"
    echo "   ./start-service.sh status  - Check status"
    echo "   ./start-service.sh logs    - View logs"
    echo "   ./start-service.sh restart - Restart"
    echo "   ./start-service.sh stop    - Stop"
}

# Method 3: Simple Background
start_simple() {
    echo "🔄 Starting simple background process..."
    
    # Create log directory
    mkdir -p /var/log/proxmox-dashboard
    
    # Start in background
    NODE_TLS_REJECT_UNAUTHORIZED=0 nohup npm run dev > /var/log/proxmox-dashboard/app.log 2>&1 &
    PID=$!
    echo $PID > /var/run/proxmox-dashboard.pid
    
    echo "✅ Started in background with PID: $PID"
    echo ""
    echo "📋 Management:"
    echo "   tail -f /var/log/proxmox-dashboard/app.log  - View logs"
    echo "   kill $PID                                   - Stop"
    echo "   kill \$(cat /var/run/proxmox-dashboard.pid) - Stop (using PID file)"
}

# Method 4: Systemd
start_systemd() {
    echo "🔄 Setting up systemd service..."
    
    # Check if running as root
    if [ "$EUID" -ne 0 ]; then
        echo "❌ Please run as root for systemd installation"
        exit 1
    fi
    
    # Install systemd service
    ./start-service.sh install-systemd
    
    # Start the service
    systemctl start proxmox-dashboard
    
    echo "✅ Systemd service installed and started!"
    echo ""
    echo "📋 Systemd Commands:"
    echo "   systemctl status proxmox-dashboard  - Check status"
    echo "   journalctl -f -u proxmox-dashboard  - View logs"
    echo "   systemctl restart proxmox-dashboard - Restart"
    echo "   systemctl stop proxmox-dashboard    - Stop"
}

# Check dependencies
echo "🔍 Checking dependencies..."

# Check Node.js
if ! command -v node >/dev/null 2>&1; then
    echo "❌ Node.js not found! Please install Node.js first."
    exit 1
fi

# Check npm
if ! command -v npm >/dev/null 2>&1; then
    echo "❌ npm not found! Please install npm first."
    exit 1
fi

# Install dependencies if needed
if [ ! -d "node_modules" ]; then
    echo "📦 Installing dependencies..."
    npm install
fi

echo "✅ Dependencies check passed"

# Choose and start
choose_method

echo ""
echo "🌐 Access your dashboard at:"
echo "   http://localhost:3000"
echo "   http://$(hostname -I | awk '{print $1}'):3000"
echo ""
echo "🎉 Proxmox Dashboard is now running!"
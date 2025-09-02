#!/bin/bash

# Fix Network Access for Proxmox Dashboard
# Make the app accessible from external network

echo "🔧 Fixing Network Access for Proxmox Dashboard"
echo "=============================================="

# Check if PM2 is running
if command -v pm2 >/dev/null 2>&1; then
    echo "📋 Current PM2 status:"
    pm2 status
    echo ""
    
    # Stop current PM2 process
    echo "🔄 Stopping current PM2 process..."
    pm2 stop proxmox-dashboard 2>/dev/null || true
    pm2 delete proxmox-dashboard 2>/dev/null || true
fi

# Create network-accessible PM2 configuration
echo "📝 Creating network-accessible PM2 configuration..."

cat > ecosystem.config.js << 'EOF'
module.exports = {
  apps: [{
    // Application settings
    name: 'proxmox-dashboard',
    script: 'npm',
    args: 'run dev',
    
    // Directory settings
    cwd: process.cwd(),
    
    // Environment variables for network access
    env: {
      NODE_TLS_REJECT_UNAUTHORIZED: '0',
      NODE_ENV: 'development',
      NEXT_TELEMETRY_DISABLED: '1',
      // Make Next.js accessible from network
      HOSTNAME: '0.0.0.0',
      PORT: '3000'
    },
    
    // Process management
    instances: 1,
    exec_mode: 'fork',
    
    // Auto-restart settings
    autorestart: true,
    watch: false,
    max_memory_restart: '1G',
    restart_delay: 3000,
    max_restarts: 10,
    min_uptime: '10s',
    
    // Logging settings
    out_file: '/var/log/proxmox-dashboard/pm2-out.log',
    error_file: '/var/log/proxmox-dashboard/pm2-error.log',
    log_file: '/var/log/proxmox-dashboard/pm2-combined.log',
    
    // Performance monitoring
    pmx: true,
    
    // Advanced settings
    kill_timeout: 5000,
    listen_timeout: 8000,
    
    // Time zone
    time: true
  }]
};
EOF

# Update package.json scripts for network access
echo "📝 Updating package.json for network access..."

# Create backup
cp package.json package.json.backup

# Update the dev script to bind to all interfaces
node -e "
const fs = require('fs');
const pkg = JSON.parse(fs.readFileSync('package.json', 'utf8'));
pkg.scripts.dev = 'NODE_TLS_REJECT_UNAUTHORIZED=0 next dev --hostname 0.0.0.0 --port 3000 --turbopack';
pkg.scripts['dev:network'] = 'NODE_TLS_REJECT_UNAUTHORIZED=0 next dev --hostname 0.0.0.0 --port 3000 --turbopack';
fs.writeFileSync('package.json', JSON.stringify(pkg, null, 2));
console.log('✅ Updated package.json scripts for network access');
"

# Create log directory
mkdir -p /var/log/proxmox-dashboard

# Start PM2 with new configuration
echo "🚀 Starting PM2 with network access..."
pm2 start ecosystem.config.js

# Save PM2 configuration
pm2 save

echo ""
echo "✅ Network access configured successfully!"
echo ""
echo "📊 PM2 Status:"
pm2 status

echo ""
echo "🌐 Your dashboard should now be accessible at:"
echo "   📱 Local: http://localhost:3000"
echo "   🌍 Network: http://$(hostname -I | awk '{print $1}'):3000"
echo "   🖥️  Direct: http://192.168.50.132:3000"
echo ""

# Check if port is listening
echo "🔍 Checking if port 3000 is accessible..."
sleep 5

if netstat -tlnp 2>/dev/null | grep -q ":3000.*0.0.0.0"; then
    echo "✅ Port 3000 is listening on all interfaces"
elif netstat -tlnp 2>/dev/null | grep -q ":3000"; then
    echo "⚠️  Port 3000 is listening but may be localhost only"
    echo "🔧 Checking PM2 logs for issues..."
    pm2 logs proxmox-dashboard --lines 10
else
    echo "❌ Port 3000 is not listening"
    echo "🔧 Checking PM2 logs for errors..."
    pm2 logs proxmox-dashboard --lines 20
fi

echo ""
echo "📋 Useful Commands:"
echo "   pm2 logs proxmox-dashboard    - View logs"
echo "   pm2 restart proxmox-dashboard - Restart service"
echo "   pm2 monit                     - Monitor performance"
echo "   netstat -tlnp | grep 3000     - Check port status"

# Test connectivity
echo ""
echo "🧪 Testing local connectivity..."
if curl -s http://localhost:3000 >/dev/null 2>&1; then
    echo "✅ Local access working"
else
    echo "❌ Local access failed"
fi

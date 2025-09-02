#!/bin/bash

# Fix PM2 npm run dev issue
# The problem is PM2 can't properly execute npm run dev with separate args

echo "🔧 Fixing PM2 npm run dev issue"
echo "================================"

# Stop current PM2 process
echo "🛑 Stopping current PM2 processes..."
pm2 stop all 2>/dev/null || true
pm2 delete all 2>/dev/null || true

# Create a wrapper script for npm run dev
echo "📝 Creating npm wrapper script..."
cat > npm-dev.sh << 'EOF'
#!/bin/bash
cd /root/proxmox-dashboard
export NODE_TLS_REJECT_UNAUTHORIZED=0
export HOSTNAME=0.0.0.0
export PORT=3000
exec npm run dev
EOF

chmod +x npm-dev.sh

# Create fixed PM2 configuration
echo "📝 Creating fixed PM2 configuration..."
cat > ecosystem.config.js << 'EOF'
module.exports = {
  apps: [{
    // Application settings
    name: 'proxmox-dashboard',
    script: './npm-dev.sh',
    
    // Directory settings
    cwd: '/root/proxmox-dashboard',
    
    // Environment variables for network access
    env: {
      NODE_TLS_REJECT_UNAUTHORIZED: '0',
      NODE_ENV: 'development',
      NEXT_TELEMETRY_DISABLED: '1',
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
    max_restarts: 15,
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

# Alternative approach - use npm directly with full command
echo "📝 Creating alternative PM2 configuration..."
cat > ecosystem-alt.config.js << 'EOF'
module.exports = {
  apps: [{
    name: 'proxmox-dashboard',
    script: 'npm',
    args: ['run', 'dev'],
    cwd: '/root/proxmox-dashboard',
    
    env: {
      NODE_TLS_REJECT_UNAUTHORIZED: '0',
      NODE_ENV: 'development',
      NEXT_TELEMETRY_DISABLED: '1',
      HOSTNAME: '0.0.0.0',
      PORT: '3000'
    },
    
    autorestart: true,
    max_restarts: 15,
    min_uptime: '10s',
    restart_delay: 3000,
    
    out_file: '/var/log/proxmox-dashboard/pm2-out.log',
    error_file: '/var/log/proxmox-dashboard/pm2-error.log'
  }]
};
EOF

# Update package.json to ensure dev script is network accessible
echo "📝 Updating package.json dev script..."
node -e "
const fs = require('fs');
const pkg = JSON.parse(fs.readFileSync('package.json', 'utf8'));
pkg.scripts.dev = 'NODE_TLS_REJECT_UNAUTHORIZED=0 next dev --hostname 0.0.0.0 --port 3000 --turbopack';
fs.writeFileSync('package.json', JSON.stringify(pkg, null, 2));
console.log('✅ Updated package.json dev script');
"

# Create log directory
mkdir -p /var/log/proxmox-dashboard

# Try the wrapper script approach first
echo "🚀 Starting PM2 with wrapper script approach..."
pm2 start ecosystem.config.js

# Wait and check
sleep 5
pm2 status

# Check if it's working
if pm2 status | grep -q "online"; then
    echo "✅ PM2 started successfully with wrapper script!"
else
    echo "⚠️  Wrapper script approach failed, trying alternative..."
    pm2 stop all 2>/dev/null || true
    pm2 delete all 2>/dev/null || true
    
    echo "🔄 Trying alternative PM2 configuration..."
    pm2 start ecosystem-alt.config.js
    
    sleep 5
    pm2 status
    
    if pm2 status | grep -q "online"; then
        echo "✅ PM2 started successfully with alternative config!"
    else
        echo "❌ Both approaches failed. Let's try direct approach..."
        pm2 stop all 2>/dev/null || true
        pm2 delete all 2>/dev/null || true
        
        # Direct approach
        echo "🔄 Trying direct npm start..."
        cd /root/proxmox-dashboard
        NODE_TLS_REJECT_UNAUTHORIZED=0 HOSTNAME=0.0.0.0 PORT=3000 pm2 start npm --name "proxmox-dashboard" -- run dev
    fi
fi

# Save PM2 configuration
pm2 save

echo ""
echo "📊 Final PM2 Status:"
pm2 status

echo ""
echo "🔍 Checking port 3000..."
sleep 3
if netstat -tlnp 2>/dev/null | grep -q ":3000"; then
    echo "✅ Port 3000 is now listening!"
    netstat -tlnp 2>/dev/null | grep ":3000"
else
    echo "❌ Port 3000 still not listening"
    echo "📝 PM2 Logs:"
    pm2 logs --lines 10
fi

echo ""
echo "🌐 Try accessing:"
echo "   http://192.168.50.132:3000"
echo ""
echo "📋 Useful commands:"
echo "   pm2 logs proxmox-dashboard    - View logs"
echo "   pm2 restart proxmox-dashboard - Restart"
echo "   pm2 monit                     - Monitor"

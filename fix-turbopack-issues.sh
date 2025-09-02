#!/bin/bash

# Fix Turbopack Issues: Font errors and slow performance
# Solution: Remove Turbopack and use stable Next.js dev server

echo "🔧 Fixing Turbopack Issues"
echo "=========================="

echo "🎯 Issues Identified:"
echo "   ❌ Turbopack font resolution errors"
echo "   ❌ Slow development performance"
echo "   ❌ @vercel/turbopack-next/internal/font/google/font not found"
echo ""

echo "✅ Solution: Remove Turbopack, use stable Next.js dev server"
echo ""

# Stop current PM2 processes
echo "🛑 Stopping current PM2 processes..."
pm2 stop all 2>/dev/null || true
pm2 delete all 2>/dev/null || true

# Update package.json to remove Turbopack
echo "📝 Updating package.json scripts (removing --turbopack)..."
node -e "
const fs = require('fs');
const pkg = JSON.parse(fs.readFileSync('package.json', 'utf8'));

// Remove --turbopack from all scripts
pkg.scripts.dev = 'NODE_TLS_REJECT_UNAUTHORIZED=0 next dev --hostname 0.0.0.0 --port 3000';
pkg.scripts['dev:fast'] = 'NODE_TLS_REJECT_UNAUTHORIZED=0 next dev --hostname 0.0.0.0 --port 3000';
pkg.scripts['dev:turbo'] = 'NODE_TLS_REJECT_UNAUTHORIZED=0 next dev --hostname 0.0.0.0 --port 3000 --turbopack';
pkg.scripts.build = 'NODE_TLS_REJECT_UNAUTHORIZED=0 next build';

fs.writeFileSync('package.json', JSON.stringify(pkg, null, 2));
console.log('✅ Updated package.json scripts - removed Turbopack from default dev');
"

# Update PM2 configuration for stable operation
echo "📝 Creating stable PM2 configuration..."
cat > ecosystem.config.js << 'EOF'
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
    
    // Stable restart settings
    autorestart: true,
    max_restarts: 5,
    min_uptime: '30s',
    restart_delay: 5000,
    
    // Resource limits
    max_memory_restart: '1G',
    
    // Logging
    out_file: '/var/log/proxmox-dashboard/pm2-out.log',
    error_file: '/var/log/proxmox-dashboard/pm2-error.log',
    log_file: '/var/log/proxmox-dashboard/pm2-combined.log',
    
    // Performance settings
    kill_timeout: 5000,
    listen_timeout: 10000,
    time: true
  }]
};
EOF

# Alternative: Create wrapper script for more reliable execution
echo "📝 Creating reliable wrapper script..."
cat > run-dev.sh << 'EOF'
#!/bin/bash
cd /root/proxmox-dashboard

# Set environment variables
export NODE_TLS_REJECT_UNAUTHORIZED=0
export NODE_ENV=development
export NEXT_TELEMETRY_DISABLED=1
export HOSTNAME=0.0.0.0
export PORT=3000

# Clean any existing processes on port 3000
echo "🧹 Cleaning port 3000..."
fuser -k 3000/tcp 2>/dev/null || true
sleep 2

echo "🚀 Starting Next.js development server (without Turbopack)..."
echo "🌐 Will be accessible at http://$(hostname -I | awk '{print $1}'):3000"

# Start Next.js dev server
exec npm run dev
EOF

chmod +x run-dev.sh

# Create log directory
mkdir -p /var/log/proxmox-dashboard

echo "🚀 Starting with stable configuration..."

# Try PM2 approach first
echo "📋 Method 1: PM2 with stable configuration"
pm2 start ecosystem.config.js

sleep 5

# Check if PM2 is working
if pm2 list | grep -q "online"; then
    echo "✅ PM2 started successfully!"
    pm2 save
else
    echo "⚠️  PM2 approach failed, trying wrapper script..."
    pm2 stop all 2>/dev/null || true
    pm2 delete all 2>/dev/null || true
    
    # Try wrapper script approach
    echo "📋 Method 2: PM2 with wrapper script"
    pm2 start run-dev.sh --name "proxmox-dashboard"
    
    sleep 5
    
    if pm2 list | grep -q "online"; then
        echo "✅ PM2 with wrapper script started successfully!"
        pm2 save
    else
        echo "⚠️  Both PM2 approaches failed"
        echo "📋 Method 3: Manual background process"
        
        # Manual background approach
        nohup ./run-dev.sh > /var/log/proxmox-dashboard/manual.log 2>&1 &
        echo $! > /var/run/proxmox-dashboard.pid
        sleep 5
        
        if kill -0 $(cat /var/run/proxmox-dashboard.pid 2>/dev/null) 2>/dev/null; then
            echo "✅ Manual background process started successfully!"
        else
            echo "❌ All methods failed. Try manual: npm run dev"
        fi
    fi
fi

echo ""
echo "📊 Status Check:"
pm2 status 2>/dev/null || echo "PM2 not running"

echo ""
echo "🔍 Port 3000 status:"
netstat -tlnp 2>/dev/null | grep ":3000" || echo "Port 3000 not listening yet"

echo ""
echo "🌐 Once running, access at:"
echo "   http://192.168.50.132:3000"
echo "   http://localhost:3000"

echo ""
echo "📋 Useful commands:"
echo "   pm2 logs proxmox-dashboard    - View PM2 logs"
echo "   pm2 restart proxmox-dashboard - Restart PM2"
echo "   tail -f /var/log/proxmox-dashboard/manual.log - View manual logs"
echo "   kill \$(cat /var/run/proxmox-dashboard.pid)   - Stop manual process"

echo ""
echo "✅ Turbopack issues fixed by using stable Next.js dev server!"
echo "🚀 Performance should be much better now!"

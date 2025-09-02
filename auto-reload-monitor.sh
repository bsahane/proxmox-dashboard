#!/bin/bash

# Auto-reload Monitor for Skynet Dashboard
# Monitors for git changes and automatically restarts the service

echo "🔄 Skynet Dashboard Auto-Reload Monitor"
echo "======================================"

LOG_DIR="/var/log/skynet-dashboard"
PID_FILE="/var/run/skynet-dashboard.pid"
RESTART_SCRIPT="./fix-turbopack-issues.sh"

mkdir -p "$LOG_DIR"

# Function to restart the dashboard
restart_dashboard() {
    echo "🔄 Restarting Skynet Dashboard..."
    
    # Stop current processes
    pm2 stop all 2>/dev/null || true
    pm2 delete all 2>/dev/null || true
    
    if [ -f "$PID_FILE" ]; then
        kill "$(cat $PID_FILE)" 2>/dev/null || true
        rm -f "$PID_FILE"
    fi
    
    # Kill any process on port 3000
    fuser -k 3000/tcp 2>/dev/null || true
    
    # Wait a moment
    sleep 3
    
    # Restart using the fix script
    if [ -f "$RESTART_SCRIPT" ]; then
        echo "✅ Using fix script to restart..."
        bash "$RESTART_SCRIPT"
    else
        echo "⚠️  Fix script not found, using npm directly..."
        export NODE_TLS_REJECT_UNAUTHORIZED=0
        nohup npm run dev > "$LOG_DIR/auto-restart.log" 2>&1 &
        echo $! > "$PID_FILE"
    fi
    
    echo "✅ Dashboard restarted!"
}

# Function to check for git changes
check_git_changes() {
    # Fetch latest changes
    git fetch origin main 2>/dev/null || return 1
    
    # Check if there are new commits
    LOCAL=$(git rev-parse HEAD)
    REMOTE=$(git rev-parse origin/main)
    
    if [ "$LOCAL" != "$REMOTE" ]; then
        echo "📥 New changes detected!"
        echo "   Local:  $LOCAL"
        echo "   Remote: $REMOTE"
        
        # Pull changes
        echo "📥 Pulling latest changes..."
        git pull origin main
        
        # Install dependencies if package.json changed
        if git diff --name-only HEAD~1 HEAD | grep -q "package.json"; then
            echo "📦 Package.json changed, updating dependencies..."
            npm install
        fi
        
        # Restart the dashboard
        restart_dashboard
        
        return 0
    fi
    
    return 1
}

# Function to check if dashboard is running
check_dashboard_status() {
    # Check PM2
    if pm2 list 2>/dev/null | grep -q "online"; then
        return 0
    fi
    
    # Check PID file
    if [ -f "$PID_FILE" ] && kill -0 "$(cat $PID_FILE)" 2>/dev/null; then
        return 0
    fi
    
    # Check port 3000
    if netstat -tlnp 2>/dev/null | grep -q ":3000"; then
        return 0
    fi
    
    return 1
}

echo "🚀 Starting auto-reload monitor..."
echo "📂 Working directory: $(pwd)"
echo "📁 Log directory: $LOG_DIR"
echo "🔄 Checking for changes every 30 seconds..."
echo ""

# Main monitoring loop
while true; do
    # Check for git changes
    if check_git_changes; then
        echo "✅ Auto-reload completed at $(date)"
    fi
    
    # Check if dashboard is still running
    if ! check_dashboard_status; then
        echo "⚠️  Dashboard not running, restarting..."
        restart_dashboard
    fi
    
    # Wait 30 seconds before next check
    sleep 30
done

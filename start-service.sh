#!/bin/bash

# Proxmox Dashboard Service Manager
# Auto-restart, background execution, and log collection

set -e

# Configuration
SERVICE_NAME="proxmox-dashboard"
APP_DIR="/root/proxmox-dashboard"
LOG_DIR="/var/log/proxmox-dashboard"
PID_FILE="/var/run/proxmox-dashboard.pid"
MAX_RESTARTS=10
RESTART_DELAY=5

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Logging function
log() {
    echo -e "${BLUE}[$(date '+%Y-%m-%d %H:%M:%S')]${NC} $1" | tee -a "$LOG_DIR/service.log"
}

error() {
    echo -e "${RED}[$(date '+%Y-%m-%d %H:%M:%S')] ERROR:${NC} $1" | tee -a "$LOG_DIR/service.log"
}

success() {
    echo -e "${GREEN}[$(date '+%Y-%m-%d %H:%M:%S')] SUCCESS:${NC} $1" | tee -a "$LOG_DIR/service.log"
}

warning() {
    echo -e "${YELLOW}[$(date '+%Y-%m-%d %H:%M:%S')] WARNING:${NC} $1" | tee -a "$LOG_DIR/service.log"
}

# Setup function
setup() {
    log "Setting up Proxmox Dashboard service..."
    
    # Create log directory
    mkdir -p "$LOG_DIR"
    chmod 755 "$LOG_DIR"
    
    # Check if app directory exists
    if [ ! -d "$APP_DIR" ]; then
        error "Application directory $APP_DIR not found!"
        exit 1
    fi
    
    # Check if package.json exists
    if [ ! -f "$APP_DIR/package.json" ]; then
        error "package.json not found in $APP_DIR!"
        exit 1
    fi
    
    # Change to app directory
    cd "$APP_DIR"
    
    # Check if npm is installed
    if ! command -v npm >/dev/null 2>&1; then
        error "npm is not installed!"
        exit 1
    fi
    
    success "Setup completed successfully"
}

# Start function with auto-restart
start_with_restart() {
    local restart_count=0
    
    while [ $restart_count -lt $MAX_RESTARTS ]; do
        log "Starting $SERVICE_NAME (attempt $((restart_count + 1))/$MAX_RESTARTS)..."
        
        # Start the npm process
        cd "$APP_DIR"
        NODE_TLS_REJECT_UNAUTHORIZED=0 npm run dev > "$LOG_DIR/app.log" 2>&1 &
        local npm_pid=$!
        
        # Save PID
        echo $npm_pid > "$PID_FILE"
        success "$SERVICE_NAME started with PID $npm_pid"
        
        # Monitor the process
        wait $npm_pid
        local exit_code=$?
        
        if [ $exit_code -eq 0 ]; then
            success "$SERVICE_NAME exited normally"
            break
        else
            error "$SERVICE_NAME crashed with exit code $exit_code"
            restart_count=$((restart_count + 1))
            
            if [ $restart_count -lt $MAX_RESTARTS ]; then
                warning "Restarting in $RESTART_DELAY seconds..."
                sleep $RESTART_DELAY
            else
                error "Maximum restart attempts ($MAX_RESTARTS) reached. Giving up."
                exit 1
            fi
        fi
    done
}

# Start function (background)
start() {
    if is_running; then
        warning "$SERVICE_NAME is already running (PID: $(cat $PID_FILE))"
        return 0
    fi
    
    setup
    
    log "Starting $SERVICE_NAME in background..."
    
    # Start the service with restart logic in background
    nohup bash -c "$(declare -f log error success warning start_with_restart); start_with_restart" > "$LOG_DIR/startup.log" 2>&1 &
    
    sleep 2
    
    if is_running; then
        success "$SERVICE_NAME started successfully!"
        show_status
    else
        error "Failed to start $SERVICE_NAME"
        return 1
    fi
}

# Stop function
stop() {
    if [ -f "$PID_FILE" ]; then
        local pid=$(cat "$PID_FILE")
        log "Stopping $SERVICE_NAME (PID: $pid)..."
        
        # Kill the process and its children
        pkill -P $pid 2>/dev/null || true
        kill $pid 2>/dev/null || true
        
        # Wait for process to stop
        local count=0
        while [ $count -lt 10 ] && kill -0 $pid 2>/dev/null; do
            sleep 1
            count=$((count + 1))
        done
        
        # Force kill if still running
        if kill -0 $pid 2>/dev/null; then
            warning "Process still running, force killing..."
            kill -9 $pid 2>/dev/null || true
        fi
        
        rm -f "$PID_FILE"
        success "$SERVICE_NAME stopped"
    else
        warning "$SERVICE_NAME is not running"
    fi
}

# Check if service is running
is_running() {
    if [ -f "$PID_FILE" ]; then
        local pid=$(cat "$PID_FILE")
        if kill -0 $pid 2>/dev/null; then
            return 0
        else
            rm -f "$PID_FILE"
            return 1
        fi
    fi
    return 1
}

# Restart function
restart() {
    log "Restarting $SERVICE_NAME..."
    stop
    sleep 2
    start
}

# Status function
status() {
    show_status
}

show_status() {
    if is_running; then
        local pid=$(cat "$PID_FILE")
        success "$SERVICE_NAME is running (PID: $pid)"
        
        # Show process info
        if command -v ps >/dev/null 2>&1; then
            echo "Process info:"
            ps aux | grep $pid | grep -v grep || true
        fi
        
        # Show port info
        if command -v netstat >/dev/null 2>&1; then
            echo "Listening ports:"
            netstat -tlnp 2>/dev/null | grep $pid || true
        fi
    else
        error "$SERVICE_NAME is not running"
        return 1
    fi
}

# Logs function
logs() {
    local follow=${1:-false}
    
    if [ "$follow" = "follow" ] || [ "$follow" = "-f" ]; then
        log "Following logs for $SERVICE_NAME (Ctrl+C to stop)..."
        tail -f "$LOG_DIR/app.log" "$LOG_DIR/service.log" 2>/dev/null
    else
        echo "=== Service Logs ==="
        if [ -f "$LOG_DIR/service.log" ]; then
            tail -50 "$LOG_DIR/service.log"
        fi
        
        echo -e "\n=== Application Logs ==="
        if [ -f "$LOG_DIR/app.log" ]; then
            tail -50 "$LOG_DIR/app.log"
        fi
        
        echo -e "\n=== Startup Logs ==="
        if [ -f "$LOG_DIR/startup.log" ]; then
            tail -20 "$LOG_DIR/startup.log"
        fi
    fi
}

# Install as systemd service
install_systemd() {
    log "Installing $SERVICE_NAME as systemd service..."
    
    cat > "/etc/systemd/system/$SERVICE_NAME.service" << EOF
[Unit]
Description=Proxmox Dashboard
After=network.target

[Service]
Type=forking
User=root
WorkingDirectory=$APP_DIR
Environment=NODE_TLS_REJECT_UNAUTHORIZED=0
ExecStart=$0 start
ExecStop=$0 stop
ExecReload=$0 restart
Restart=always
RestartSec=5
StandardOutput=journal
StandardError=journal

[Install]
WantedBy=multi-user.target
EOF

    systemctl daemon-reload
    systemctl enable "$SERVICE_NAME"
    success "Systemd service installed and enabled"
    log "You can now use: systemctl start/stop/restart $SERVICE_NAME"
}

# Help function
help() {
    echo "Proxmox Dashboard Service Manager"
    echo ""
    echo "Usage: $0 {start|stop|restart|status|logs|install-systemd|help}"
    echo ""
    echo "Commands:"
    echo "  start             Start the service in background with auto-restart"
    echo "  stop              Stop the service"
    echo "  restart           Restart the service"
    echo "  status            Show service status"
    echo "  logs              Show recent logs"
    echo "  logs follow       Follow logs in real-time"
    echo "  install-systemd   Install as systemd service"
    echo "  help              Show this help message"
    echo ""
    echo "Log files located in: $LOG_DIR"
    echo "  - service.log     Service management logs"
    echo "  - app.log         Application output logs"
    echo "  - startup.log     Startup process logs"
}

# Main function
main() {
    case "${1:-help}" in
        start)
            start
            ;;
        stop)
            stop
            ;;
        restart)
            restart
            ;;
        status)
            status
            ;;
        logs)
            logs "${2:-}"
            ;;
        install-systemd)
            install_systemd
            ;;
        help|--help|-h)
            help
            ;;
        *)
            error "Unknown command: $1"
            help
            exit 1
            ;;
    esac
}

# Run main function
main "$@"

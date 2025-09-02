#!/bin/bash

# Proxmox Dashboard Deployment Script
# Detects architecture and deploys the container with port configuration

set -e

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
PURPLE='\033[0;35m'
CYAN='\033[0;36m'
WHITE='\033[1;37m'
NC='\033[0m' # No Color

# Default values
DEFAULT_PORT=7070
DEFAULT_PROXMOX_HOST="https://192.168.50.7:8006"
DEFAULT_GUACAMOLE_HOST="http://192.168.50.183:8080"
CONTAINER_NAME="proxmox-dashboard"
IMAGE_NAME="proxmox-dashboard"

# Function to print colored output
print_status() {
    echo -e "${GREEN}[INFO]${NC} $1"
}

print_warning() {
    echo -e "${YELLOW}[WARN]${NC} $1"
}

print_error() {
    echo -e "${RED}[ERROR]${NC} $1"
}

print_header() {
    echo -e "${PURPLE}[DEPLOY]${NC} $1"
}

# Function to detect architecture
detect_architecture() {
    local arch=$(uname -m)
    case $arch in
        x86_64)
            echo "amd64"
            ;;
        aarch64|arm64)
            echo "arm64"
            ;;
        armv7l)
            echo "arm/v7"
            ;;
        armv6l)
            echo "arm/v6"
            ;;
        *)
            echo "unknown"
            ;;
    esac
}

# Function to detect container runtime
detect_container_runtime() {
    if command -v podman &> /dev/null; then
        echo "podman"
    elif command -v docker &> /dev/null; then
        echo "docker"
    else
        echo "none"
    fi
}

# Function to check if port is available
check_port() {
    local port=$1
    if lsof -Pi :$port -sTCP:LISTEN -t >/dev/null 2>&1; then
        return 1
    else
        return 0
    fi
}

# Function to get user input with default value
get_input() {
    local prompt="$1"
    local default="$2"
    local input
    
    echo -e "${CYAN}$prompt${NC} ${WHITE}[default: $default]${NC}: "
    read -r input
    echo "${input:-$default}"
}

# Function to build container
build_container() {
    local runtime=$1
    local arch=$2
    
    print_status "Building container for $arch architecture..."
    
    if [ "$runtime" = "podman" ]; then
        podman build \
            --platform=linux/$arch \
            --tag $IMAGE_NAME:latest \
            --file Containerfile \
            .
    else
        docker build \
            --platform=linux/$arch \
            --tag $IMAGE_NAME:latest \
            --file Containerfile \
            .
    fi
}

# Function to stop existing container
stop_existing_container() {
    local runtime=$1
    
    if $runtime container exists $CONTAINER_NAME 2>/dev/null; then
        print_warning "Stopping existing container..."
        $runtime stop $CONTAINER_NAME 2>/dev/null || true
        $runtime rm $CONTAINER_NAME 2>/dev/null || true
    fi
}

# Function to run container
run_container() {
    local runtime=$1
    local port=$2
    local proxmox_host=$3
    local guacamole_host=$4
    
    print_status "Starting container on port $port..."
    
    $runtime run -d \
        --name $CONTAINER_NAME \
        --restart unless-stopped \
        -p $port:3000 \
        --env-file .env \
        $IMAGE_NAME:latest
}

# Main deployment function
main() {
    echo -e "${PURPLE}"
    echo "╔══════════════════════════════════════════════════════════════╗"
    echo "║                 PROXMOX DASHBOARD DEPLOYER                  ║"
    echo "║                                                              ║"
    echo "║  🚀 Modern Dashboard for Proxmox VE Management              ║"
    echo "║  🎮 Integrated Apache Guacamole Console Access             ║"
    echo "║  🎨 Beautiful ShadCN UI with Responsive Design             ║"
    echo "╚══════════════════════════════════════════════════════════════╝"
    echo -e "${NC}"
    
    # Detect system information
    local arch=$(detect_architecture)
    local runtime=$(detect_container_runtime)
    
    print_header "System Detection"
    print_status "Architecture: $(uname -m) -> $arch"
    print_status "Container Runtime: $runtime"
    
    # Check container runtime
    if [ "$runtime" = "none" ]; then
        print_error "No container runtime found! Please install Docker or Podman."
        exit 1
    fi
    
    if [ "$arch" = "unknown" ]; then
        print_warning "Unknown architecture detected. Proceeding with amd64..."
        arch="amd64"
    fi
    
    echo ""
    print_header "Configuration"
    
    # Get port configuration
    local port
    while true; do
        port=$(get_input "Enter port for dashboard" "$DEFAULT_PORT")
        
        if ! [[ "$port" =~ ^[0-9]+$ ]] || [ "$port" -lt 1 ] || [ "$port" -gt 65535 ]; then
            print_error "Invalid port number. Please enter a number between 1-65535."
            continue
        fi
        
        if ! check_port "$port"; then
            print_error "Port $port is already in use. Please choose another port."
            continue
        fi
        
        break
    done
    
    # Get Proxmox configuration
    local proxmox_host=$(get_input "Enter Proxmox server URL" "$DEFAULT_PROXMOX_HOST")
    local guacamole_host=$(get_input "Enter Guacamole server URL" "$DEFAULT_GUACAMOLE_HOST")
    
    # Create .env file for container
    echo "Creating .env configuration..."
    cat > .env << EOF
# Proxmox Dashboard Configuration
PROXMOX_HOST=$proxmox_host
GUACAMOLE_HOST=$guacamole_host
NODE_TLS_REJECT_UNAUTHORIZED=0
NEXT_TELEMETRY_DISABLED=1
NODE_ENV=production
PROXMOX_API_TIMEOUT=30000
DASHBOARD_REFRESH_INTERVAL=30
DEBUG_LOGGING=false
EOF
    
    echo ""
    print_header "Deployment Summary"
    echo -e "${WHITE}Container Runtime:${NC} $runtime"
    echo -e "${WHITE}Architecture:${NC} $arch"
    echo -e "${WHITE}Dashboard Port:${NC} $port"
    echo -e "${WHITE}Proxmox Server:${NC} $proxmox_host"
    echo -e "${WHITE}Guacamole Server:${NC} $guacamole_host"
    echo ""
    
    # Confirm deployment
    echo -e "${CYAN}Proceed with deployment? [Y/n]:${NC} "
    read -r confirm
    if [[ $confirm =~ ^[Nn]$ ]]; then
        print_warning "Deployment cancelled by user."
        exit 0
    fi
    
    echo ""
    print_header "Building and Deploying"
    
    # Stop existing container
    stop_existing_container "$runtime"
    
    # Build container
    build_container "$runtime" "$arch"
    
    # Run container
    run_container "$runtime" "$port" "$proxmox_host" "$guacamole_host"
    
    echo ""
    print_header "Deployment Complete!"
    echo -e "${GREEN}✅ Container deployed successfully!${NC}"
    echo ""
    echo -e "${WHITE}🌐 Dashboard URL:${NC} ${CYAN}http://localhost:$port${NC}"
    echo -e "${WHITE}🖥️  Network URL:${NC} ${CYAN}http://$(hostname -I | awk '{print $1}'):$port${NC}"
    echo ""
    echo -e "${WHITE}📊 Container Status:${NC}"
    $runtime ps --filter name=$CONTAINER_NAME --format "table {{.Names}}\t{{.Status}}\t{{.Ports}}"
    echo ""
    echo -e "${WHITE}📝 Container Logs:${NC} ${YELLOW}$runtime logs -f $CONTAINER_NAME${NC}"
    echo -e "${WHITE}🛑 Stop Container:${NC} ${YELLOW}$runtime stop $CONTAINER_NAME${NC}"
    echo -e "${WHITE}🗑️  Remove Container:${NC} ${YELLOW}$runtime rm $CONTAINER_NAME${NC}"
    echo ""
    print_status "Login with your Proxmox credentials (username@realm format)"
    print_status "Example: root@pam or admin@pve"
}

# Check if script is run directly
if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
    main "$@"
fi

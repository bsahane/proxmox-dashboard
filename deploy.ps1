# Proxmox Dashboard Deployment Script for Windows PowerShell
# Detects architecture and deploys the container with port configuration

param(
    [int]$Port = 7070,
    [string]$ProxmoxHost = "https://192.168.50.7:8006",
    [string]$GuacamoleHost = "http://192.168.50.183:8080",
    [switch]$Force
)

# Default values
$ContainerName = "proxmox-dashboard"
$ImageName = "proxmox-dashboard"

# Function to write colored output
function Write-Status {
    param([string]$Message)
    Write-Host "[INFO] $Message" -ForegroundColor Green
}

function Write-Warning {
    param([string]$Message)
    Write-Host "[WARN] $Message" -ForegroundColor Yellow
}

function Write-Error {
    param([string]$Message)
    Write-Host "[ERROR] $Message" -ForegroundColor Red
}

function Write-Header {
    param([string]$Message)
    Write-Host "[DEPLOY] $Message" -ForegroundColor Magenta
}

# Function to detect architecture
function Get-Architecture {
    $arch = [System.Runtime.InteropServices.RuntimeInformation]::OSArchitecture
    switch ($arch) {
        "X64" { return "amd64" }
        "Arm64" { return "arm64" }
        "Arm" { return "arm/v7" }
        default { return "unknown" }
    }
}

# Function to detect container runtime
function Get-ContainerRuntime {
    if (Get-Command podman -ErrorAction SilentlyContinue) {
        return "podman"
    }
    elseif (Get-Command docker -ErrorAction SilentlyContinue) {
        return "docker"
    }
    else {
        return "none"
    }
}

# Function to check if port is available
function Test-Port {
    param([int]$Port)
    try {
        $listener = [System.Net.Sockets.TcpListener]::new([System.Net.IPAddress]::Any, $Port)
        $listener.Start()
        $listener.Stop()
        return $true
    }
    catch {
        return $false
    }
}

# Function to get user input with default value
function Get-UserInput {
    param(
        [string]$Prompt,
        [string]$Default
    )
    $input = Read-Host "$Prompt [default: $Default]"
    if ([string]::IsNullOrWhiteSpace($input)) {
        return $Default
    }
    return $input
}

# Function to build container
function Build-Container {
    param(
        [string]$Runtime,
        [string]$Architecture
    )
    
    Write-Status "Building container for $Architecture architecture..."
    
    if ($Runtime -eq "podman") {
        & podman build --platform=linux/$Architecture --tag "$ImageName`:latest" --file Containerfile .
    }
    else {
        & docker build --platform=linux/$Architecture --tag "$ImageName`:latest" --file Containerfile .
    }
    
    if ($LASTEXITCODE -ne 0) {
        throw "Container build failed"
    }
}

# Function to stop existing container
function Stop-ExistingContainer {
    param([string]$Runtime)
    
    $exists = & $Runtime container exists $ContainerName 2>$null
    if ($LASTEXITCODE -eq 0) {
        Write-Warning "Stopping existing container..."
        & $Runtime stop $ContainerName 2>$null
        & $Runtime rm $ContainerName 2>$null
    }
}

# Function to run container
function Start-Container {
    param(
        [string]$Runtime,
        [int]$Port,
        [string]$ProxmoxHost,
        [string]$GuacamoleHost
    )
    
    Write-Status "Starting container on port $Port..."
    
    & $Runtime run -d `
        --name $ContainerName `
        --restart unless-stopped `
        -p "$Port`:3000" `
        -e NODE_ENV=production `
        -e NODE_TLS_REJECT_UNAUTHORIZED=0 `
        -e NEXT_TELEMETRY_DISABLED=1 `
        -e PROXMOX_HOST="$ProxmoxHost" `
        -e GUACAMOLE_HOST="$GuacamoleHost" `
        "$ImageName`:latest"
    
    if ($LASTEXITCODE -ne 0) {
        throw "Failed to start container"
    }
}

# Main deployment function
function Main {
    Write-Host @"
╔══════════════════════════════════════════════════════════════╗
║                 PROXMOX DASHBOARD DEPLOYER                  ║
║                                                              ║
║  🚀 Modern Dashboard for Proxmox VE Management              ║
║  🎮 Integrated Apache Guacamole Console Access             ║
║  🎨 Beautiful ShadCN UI with Responsive Design             ║
╚══════════════════════════════════════════════════════════════╝
"@ -ForegroundColor Magenta
    
    # Detect system information
    $arch = Get-Architecture
    $runtime = Get-ContainerRuntime
    
    Write-Header "System Detection"
    Write-Status "Architecture: $([System.Runtime.InteropServices.RuntimeInformation]::OSArchitecture) -> $arch"
    Write-Status "Container Runtime: $runtime"
    
    # Check container runtime
    if ($runtime -eq "none") {
        Write-Error "No container runtime found! Please install Docker or Podman."
        exit 1
    }
    
    if ($arch -eq "unknown") {
        Write-Warning "Unknown architecture detected. Proceeding with amd64..."
        $arch = "amd64"
    }
    
    Write-Host ""
    Write-Header "Configuration"
    
    # Get port configuration if not provided
    if (-not $Force) {
        while ($true) {
            $portInput = Get-UserInput "Enter port for dashboard" $Port
            $Port = [int]$portInput
            
            if ($Port -lt 1 -or $Port -gt 65535) {
                Write-Error "Invalid port number. Please enter a number between 1-65535."
                continue
            }
            
            if (-not (Test-Port $Port)) {
                Write-Error "Port $Port is already in use. Please choose another port."
                continue
            }
            
            break
        }
        
        # Get Proxmox configuration
        $ProxmoxHost = Get-UserInput "Enter Proxmox server URL" $ProxmoxHost
        $GuacamoleHost = Get-UserInput "Enter Guacamole server URL" $GuacamoleHost
    }
    
    Write-Host ""
    Write-Header "Deployment Summary"
    Write-Host "Container Runtime: $runtime" -ForegroundColor White
    Write-Host "Architecture: $arch" -ForegroundColor White
    Write-Host "Dashboard Port: $Port" -ForegroundColor White
    Write-Host "Proxmox Server: $ProxmoxHost" -ForegroundColor White
    Write-Host "Guacamole Server: $GuacamoleHost" -ForegroundColor White
    Write-Host ""
    
    # Confirm deployment
    if (-not $Force) {
        $confirm = Read-Host "Proceed with deployment? [Y/n]"
        if ($confirm -match "^[Nn]$") {
            Write-Warning "Deployment cancelled by user."
            return
        }
    }
    
    Write-Host ""
    Write-Header "Building and Deploying"
    
    try {
        # Stop existing container
        Stop-ExistingContainer $runtime
        
        # Build container
        Build-Container $runtime $arch
        
        # Run container
        Start-Container $runtime $Port $ProxmoxHost $GuacamoleHost
        
        Write-Host ""
        Write-Header "Deployment Complete!"
        Write-Host "✅ Container deployed successfully!" -ForegroundColor Green
        Write-Host ""
        Write-Host "🌐 Dashboard URL: " -ForegroundColor White -NoNewline
        Write-Host "http://localhost:$Port" -ForegroundColor Cyan
        
        # Try to get network IP
        try {
            $networkIP = (Get-NetIPAddress -AddressFamily IPv4 | Where-Object { $_.InterfaceAlias -notlike "*Loopback*" -and $_.IPAddress -notlike "169.254.*" } | Select-Object -First 1).IPAddress
            Write-Host "🖥️  Network URL: " -ForegroundColor White -NoNewline
            Write-Host "http://$networkIP`:$Port" -ForegroundColor Cyan
        } catch {
            # Ignore network IP detection errors
        }
        
        Write-Host ""
        Write-Host "📊 Container Status:" -ForegroundColor White
        & $runtime ps --filter name=$ContainerName --format "table {{.Names}}`t{{.Status}}`t{{.Ports}}"
        Write-Host ""
        Write-Host "📝 Container Logs: " -ForegroundColor White -NoNewline
        Write-Host "$runtime logs -f $ContainerName" -ForegroundColor Yellow
        Write-Host "🛑 Stop Container: " -ForegroundColor White -NoNewline
        Write-Host "$runtime stop $ContainerName" -ForegroundColor Yellow
        Write-Host "🗑️  Remove Container: " -ForegroundColor White -NoNewline
        Write-Host "$runtime rm $ContainerName" -ForegroundColor Yellow
        Write-Host ""
        Write-Status "Login with your Proxmox credentials (username@realm format)"
        Write-Status "Example: root@pam or admin@pve"
    }
    catch {
        Write-Error "Deployment failed: $($_.Exception.Message)"
        exit 1
    }
}

# Run main function
Main

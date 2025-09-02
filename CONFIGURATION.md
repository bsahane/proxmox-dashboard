# 🔧 Configuration Guide

## Environment Variables

The Proxmox Dashboard uses environment variables for configuration. This allows easy deployment across different environments (development, production, Docker, etc.).

### Quick Start

1. **Copy the example configuration:**
```bash
cp .env.example .env.local
```

2. **Edit with your values:**
```bash
nano .env.local
```

3. **Required variables:**
```env
PROXMOX_HOST=https://your-proxmox-server:8006
GUACAMOLE_HOST=http://your-guacamole-server:8080
```

## Configuration Files

### `.env.example`
Template file with all available options and descriptions. Never edit this file directly.

### `.env.local` (Development)
Your local configuration for development. This file is gitignored and safe for secrets.

### `.env` (Production)
Production configuration file. Used by Docker containers and production deployments.

## Available Variables

### 🖥️ **Server Configuration**

| Variable | Description | Default | Example |
|----------|-------------|---------|---------|
| `PROXMOX_HOST` | Proxmox VE server URL | `https://192.168.50.7:8006` | `https://pve.company.com:8006` |
| `GUACAMOLE_HOST` | Apache Guacamole server URL | `http://192.168.50.183:8080` | `https://guac.company.com` |

### 🔒 **Security Configuration**

| Variable | Description | Default | Values |
|----------|-------------|---------|---------|
| `NODE_TLS_REJECT_UNAUTHORIZED` | SSL certificate validation | `0` | `0` (disable), `1` (enable) |
| `NEXT_TELEMETRY_DISABLED` | Disable Next.js telemetry | `1` | `0`, `1` |

### ⚙️ **Application Settings**

| Variable | Description | Default | Example |
|----------|-------------|---------|---------|
| `PROXMOX_API_TIMEOUT` | API request timeout (ms) | `30000` | `60000` |
| `DASHBOARD_REFRESH_INTERVAL` | Auto-refresh interval (seconds) | `30` | `60` |
| `DEBUG_LOGGING` | Enable debug logs | `false` | `true`, `false` |
| `NODE_ENV` | Application environment | `development` | `production` |

## Deployment Methods

### 🖥️ **Development (Local)**

1. **Create configuration:**
```bash
cp .env.example .env.local
```

2. **Edit values:**
```env
PROXMOX_HOST=https://192.168.50.7:8006
GUACAMOLE_HOST=http://192.168.50.183:8080
NODE_TLS_REJECT_UNAUTHORIZED=0
```

3. **Start development server:**
```bash
npm run dev
```

### 🐳 **Docker Compose**

1. **Method A - Environment file (Recommended):**
```bash
cp .env.example .env
# Edit .env with your values
docker-compose up -d
```

2. **Method B - Edit docker-compose.yml:**
```yaml
services:
  proxmox-dashboard:
    environment:
      - PROXMOX_HOST=https://your-server:8006
      - GUACAMOLE_HOST=http://your-guacamole:8080
```

### 🐋 **Docker Run**

```bash
docker run -d \
  --name proxmox-dashboard \
  -p 3000:3000 \
  -e PROXMOX_HOST=https://your-server:8006 \
  -e GUACAMOLE_HOST=http://your-guacamole:8080 \
  -e NODE_TLS_REJECT_UNAUTHORIZED=0 \
  proxmox-dashboard:latest
```

### 🚀 **Production Server**

1. **Create production config:**
```bash
cp .env.example .env
```

2. **Set production values:**
```env
PROXMOX_HOST=https://proxmox.company.com:8006
GUACAMOLE_HOST=https://guacamole.company.com
NODE_ENV=production
NODE_TLS_REJECT_UNAUTHORIZED=1
```

3. **Build and start:**
```bash
npm run build
npm start
```

## Configuration Validation

The application automatically validates configuration on startup:

### ✅ **Valid Configuration**
- All URLs are properly formatted
- Timeout values are reasonable (≥1000ms)
- Refresh intervals are practical (≥5 seconds)

### ❌ **Invalid Configuration**
The application will show error messages for:
- Malformed URLs
- Invalid timeout values
- Missing required variables

## Security Best Practices

### 🔒 **SSL Certificates**

**Development:**
```env
NODE_TLS_REJECT_UNAUTHORIZED=0  # Allow self-signed certificates
```

**Production:**
```env
NODE_TLS_REJECT_UNAUTHORIZED=1  # Require valid certificates
```

### 🛡️ **Network Security**

1. **Use HTTPS** for Proxmox in production
2. **Use HTTPS** for Guacamole in production  
3. **Configure firewalls** to restrict access
4. **Use VPN** for remote access

### 🔐 **Access Control**

1. **Create dedicated Proxmox user** with minimal permissions
2. **Use strong passwords** for all accounts
3. **Enable two-factor authentication** where possible
4. **Regular security updates** for all components

## Troubleshooting

### 🔍 **Connection Issues**

1. **Check URLs:**
```bash
curl -k https://your-proxmox-server:8006/api2/json/version
```

2. **Test from container:**
```bash
docker exec -it proxmox-dashboard curl -k $PROXMOX_HOST/api2/json/version
```

### 🐛 **Debug Mode**

Enable detailed logging:
```env
DEBUG_LOGGING=true
NODE_ENV=development
```

### 📋 **Configuration Check**

The dashboard provides a config API endpoint:
```bash
curl http://localhost:3000/api/config
```

## Examples

### 🏠 **Home Lab Setup**
```env
PROXMOX_HOST=https://192.168.1.100:8006
GUACAMOLE_HOST=http://192.168.1.101:8080
NODE_TLS_REJECT_UNAUTHORIZED=0
DASHBOARD_REFRESH_INTERVAL=30
```

### 🏢 **Enterprise Setup**
```env
PROXMOX_HOST=https://proxmox.company.com:8006
GUACAMOLE_HOST=https://remote.company.com
NODE_TLS_REJECT_UNAUTHORIZED=1
PROXMOX_API_TIMEOUT=60000
DASHBOARD_REFRESH_INTERVAL=60
```

### ☁️ **Cloud Setup**
```env
PROXMOX_HOST=https://proxmox-01.cloud.company.com:8006
GUACAMOLE_HOST=https://guac-01.cloud.company.com
NODE_TLS_REJECT_UNAUTHORIZED=1
DASHBOARD_REFRESH_INTERVAL=45
```

# 🚀 Proxmox Dashboard

A modern, beautiful web dashboard for managing Proxmox Virtual Environment (PVE) with integrated Apache Guacamole console access.

![Proxmox Dashboard](https://img.shields.io/badge/Proxmox-Dashboard-blue?style=for-the-badge&logo=proxmox)
![Next.js](https://img.shields.io/badge/Next.js-14-black?style=for-the-badge&logo=next.js)
![TypeScript](https://img.shields.io/badge/TypeScript-007ACC?style=for-the-badge&logo=typescript&logoColor=white)
![TailwindCSS](https://img.shields.io/badge/Tailwind_CSS-38B2AC?style=for-the-badge&logo=tailwind-css&logoColor=white)

## ✨ Features

### 🔐 **Secure Authentication**
- PAM (Local Users) and PVE (Proxmox Users) realm support
- Active Directory and LDAP integration ready
- Session management with secure token storage
- Auto-logout and session persistence

### 🖥️ **VM & LXC Management**
- **Real-time Dashboard** with live status updates
- **Start, Stop, Reset** operations with one click
- **Resource Monitoring** (CPU, Memory, Disk usage)
- **Uptime Tracking** for running instances
- **Node-based Filtering** and search capabilities

### 🎮 **Integrated Console Access**
- **Apache Guacamole Integration** for seamless console access
- One-click console launch in new tabs
- Direct connection to VMs and LXCs
- No additional software required

### 🎨 **Modern UI/UX**
- **ShadCN UI Components** for professional appearance
- **Responsive Design** - works on desktop, tablet, and mobile
- **Dark/Light Mode** support (coming soon)
- **Real-time Updates** every 30 seconds
- **Progressive Web App** capabilities

### 🔧 **Advanced Features**
- **Snapshot Management** (restore last snapshot)
- **Bulk Operations** support
- **Search and Filtering** by name, status, and node
- **Error Handling** with user-friendly messages
- **SSL Certificate** handling for self-signed certificates

## 🚀 Quick Start

### Prerequisites
- **Node.js 18+**
- **Proxmox VE Server** (tested with PVE 7.x+)
- **Apache Guacamole** (optional, for console access)

### Installation

1. **Clone the repository**
```bash
git clone <your-repo-url>
cd proxmox-dashboard
```

2. **Install dependencies**
```bash
npm install
```

3. **Configure your environment**
```bash
cp .env.example .env.local
```

Edit `.env.local` with your server details:
```env
# Required Configuration
PROXMOX_HOST=https://your-proxmox-server:8006
GUACAMOLE_HOST=http://your-guacamole-server:8080

# Security (for self-signed certificates)
NODE_TLS_REJECT_UNAUTHORIZED=0

# Optional Settings
PROXMOX_API_TIMEOUT=30000
DASHBOARD_REFRESH_INTERVAL=30
DEBUG_LOGGING=false
```

4. **Start the development server**
```bash
npm run dev
```

5. **Open your browser**
```
http://localhost:3000
```

## 🐳 Docker Deployment

### Using Docker Compose (Recommended)

1. **Clone and configure**
```bash
git clone <your-repo-url>
cd proxmox-dashboard
```

2. **Configure environment**
Option A - Edit `docker-compose.yml` environment variables:
```yaml
environment:
  - PROXMOX_HOST=https://your-server:8006
  - GUACAMOLE_HOST=http://your-guacamole:8080
```

Option B - Create `.env` file (recommended):
```bash
cp .env.example .env
# Edit .env with your actual values
```

3. **Deploy**
```bash
docker-compose up -d
```

### Using Podman

```bash
# Build the container
podman build -t proxmox-dashboard .

# Run the container
podman run -d \
  --name proxmox-dashboard \
  -p 3000:3000 \
  -e NODE_TLS_REJECT_UNAUTHORIZED=0 \
  -e PROXMOX_HOST=https://192.168.50.7:8006 \
  -e GUACAMOLE_HOST=http://192.168.50.183:8080 \
  proxmox-dashboard
```

### Using Docker

```bash
# Build the image
docker build -t proxmox-dashboard .

# Run the container
docker run -d \
  --name proxmox-dashboard \
  -p 3000:3000 \
  -e NODE_TLS_REJECT_UNAUTHORIZED=0 \
  -e PROXMOX_HOST=https://192.168.50.7:8006 \
  -e GUACAMOLE_HOST=http://192.168.50.183:8080 \
  proxmox-dashboard
```

## 🔧 Configuration

### Proxmox Configuration

1. **API Access**: Ensure your Proxmox user has appropriate permissions:
   - VM.Audit (to view VMs)
   - VM.PowerMgmt (to start/stop/reset VMs)
   - VM.Console (for console access)

2. **CORS Settings**: If needed, configure CORS in Proxmox for your domain.

3. **SSL Certificates**: The dashboard handles self-signed certificates automatically.

### Guacamole Configuration

1. **Connection Setup**: Configure your VM connections in Guacamole
2. **User Permissions**: Ensure users have access to their respective VMs
3. **Network Access**: Ensure the dashboard can reach your Guacamole server

## 📱 Usage

### Login
1. Navigate to the dashboard URL
2. Select your authentication realm (PAM, PVE, AD, LDAP)
3. Enter your username and password
4. Click "Sign in"

### Managing VMs
- **View All VMs**: Dashboard shows all accessible VMs and LXCs
- **Start VM**: Click the green "Start" button
- **Stop VM**: Click the red "Stop" button  
- **Reset VM**: Use the dropdown menu and select "Reset"
- **Console Access**: Click "Console" to open Guacamole in a new tab

### Filtering and Search
- **Search**: Use the search bar to find VMs by name or ID
- **Filter by Status**: Show only running, stopped, or all VMs
- **Filter by Node**: Show VMs from specific Proxmox nodes
- **View Modes**: Toggle between grid and table views

## 🏗️ Architecture

### Frontend
- **Next.js 14** with App Router
- **TypeScript** for type safety
- **ShadCN UI** components with Tailwind CSS
- **Zustand** for state management
- **React Query** for server state management

### Backend
- **Next.js API Routes** for secure proxying
- **Proxmox REST API** integration
- **Apache Guacamole API** integration
- **JWT-based** session management

### Security
- **SSL/TLS** support with self-signed certificate handling
- **CSRF** protection
- **Input validation** and sanitization
- **Secure headers** and CORS policies

## 🛠️ Development

### Tech Stack
- **Framework**: Next.js 14 with TypeScript
- **UI Library**: ShadCN UI (Radix UI + Tailwind CSS)
- **State Management**: Zustand + React Query
- **HTTP Client**: Axios
- **Icons**: Lucide React
- **Styling**: Tailwind CSS

### Available Scripts
```bash
npm run dev          # Start development server
npm run build        # Build for production
npm run start        # Start production server
npm run lint         # Run ESLint
npm run type-check   # Run TypeScript check
```

### Project Structure
```
proxmox-dashboard/
├── src/
│   ├── app/                    # Next.js App Router pages
│   │   ├── api/               # API routes (Proxmox proxy)
│   │   ├── dashboard/         # Dashboard page
│   │   └── login/            # Login page
│   ├── components/           # React components
│   │   ├── ui/              # ShadCN UI components
│   │   └── dashboard/       # Dashboard-specific components
│   └── lib/                 # Utilities and services
│       ├── proxmox.ts      # Proxmox API client
│       ├── store.ts        # Zustand stores
│       └── utils.ts        # Utility functions
├── public/                  # Static assets
├── Containerfile           # Docker/Podman container definition
├── docker-compose.yml      # Docker Compose configuration
└── README.md               # This file
```

## 🔍 Troubleshooting

### Common Issues

**1. SSL Certificate Errors**
```bash
# Solution: Set environment variable
NODE_TLS_REJECT_UNAUTHORIZED=0
```

**2. Authentication Failures**
- Verify Proxmox server URL is correct
- Check username format (should include realm: `user@pam`)
- Ensure user has necessary permissions

**3. VM Operations Not Working**
- Check user permissions in Proxmox
- Verify VM is not locked or in a protected state
- Check Proxmox server logs for detailed errors

**4. Console Access Issues**
- Verify Guacamole server is accessible
- Check Guacamole connection configurations
- Ensure proper network connectivity

### Debug Mode
Enable debug logging by setting:
```env
NODE_ENV=development
```

## 🤝 Contributing

We welcome contributions! Please see our [Contributing Guide](CONTRIBUTING.md) for details.

### Development Setup
1. Fork the repository
2. Create a feature branch
3. Make your changes
4. Add tests if applicable
5. Submit a pull request

## 📄 License

This project is licensed under the MIT License - see the [LICENSE](LICENSE) file for details.

## 🙏 Acknowledgments

- **Proxmox Team** for the excellent virtualization platform
- **Apache Guacamole** for the remote desktop gateway
- **ShadCN** for the beautiful UI components
- **Vercel** for the Next.js framework

## 📞 Support

- **Documentation**: See this README and inline code comments
- **Issues**: Report bugs and feature requests via GitHub Issues
- **Community**: Join our discussions for help and feedback

---

**Built with ❤️ for the Proxmox community**

![Dashboard Preview](https://via.placeholder.com/800x400/1a1a1a/white?text=Proxmox+Dashboard+Preview)
# How to Keep Proxmox Dashboard Running

## Option 1: Using PM2 (Recommended)

### Install PM2:
```bash
npm install -g pm2
```

### Create PM2 ecosystem file:
```bash
# Create ecosystem.config.js
cat > ecosystem.config.js << 'EOF'
module.exports = {
  apps: [{
    name: 'proxmox-dashboard',
    script: 'npm',
    args: 'run dev',
    cwd: '/root/proxmox-dashboard',
    env: {
      NODE_TLS_REJECT_UNAUTHORIZED: '0',
      NODE_ENV: 'development'
    },
    watch: false,
    restart_delay: 1000,
    max_restarts: 10,
    min_uptime: '10s'
  }]
}
EOF
```

### Start with PM2:
```bash
pm2 start ecosystem.config.js
pm2 save                 # Save PM2 configuration
pm2 startup              # Auto-start on system boot
```

### PM2 Commands:
```bash
pm2 status              # Check status
pm2 logs proxmox-dashboard  # View logs
pm2 restart proxmox-dashboard  # Restart
pm2 stop proxmox-dashboard     # Stop
```

## Option 2: Using Screen/Tmux

### Using Screen:
```bash
screen -S proxmox-dashboard
cd /root/proxmox-dashboard
npm run dev
# Press Ctrl+A then D to detach
# screen -r proxmox-dashboard to reattach
```

### Using Tmux:
```bash
tmux new-session -d -s proxmox-dashboard
tmux send-keys -t proxmox-dashboard "cd /root/proxmox-dashboard && npm run dev" Enter
# tmux attach-session -t proxmox-dashboard to reattach
```

## Option 3: Systemd Service

### Create service file:
```bash
sudo tee /etc/systemd/system/proxmox-dashboard.service << 'EOF'
[Unit]
Description=Proxmox Dashboard
After=network.target

[Service]
Type=simple
User=root
WorkingDirectory=/root/proxmox-dashboard
Environment=NODE_TLS_REJECT_UNAUTHORIZED=0
ExecStart=/usr/bin/npm run dev
Restart=always
RestartSec=5

[Install]
WantedBy=multi-user.target
EOF
```

### Enable and start:
```bash
sudo systemctl enable proxmox-dashboard
sudo systemctl start proxmox-dashboard
sudo systemctl status proxmox-dashboard
```

## Option 4: Simple Background Process

```bash
# Run in background with nohup
nohup npm run dev > /var/log/proxmox-dashboard.log 2>&1 &
echo $! > /var/run/proxmox-dashboard.pid

# To stop:
kill $(cat /var/run/proxmox-dashboard.pid)
```

## Recommended: PM2 for Development, Docker for Production

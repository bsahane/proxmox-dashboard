// PM2 Configuration for Proxmox Dashboard
// Advanced process management with auto-restart and logging

module.exports = {
  apps: [{
    // Application settings
    name: 'proxmox-dashboard',
    script: 'npm',
    args: 'run dev',
    
    // Directory settings
    cwd: '/root/proxmox-dashboard',
    
    // Environment variables
    env: {
      NODE_TLS_REJECT_UNAUTHORIZED: '0',
      NODE_ENV: 'development',
      NEXT_TELEMETRY_DISABLED: '1'
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
    log_type: 'json',
    log_date_format: 'YYYY-MM-DD HH:mm:ss Z',
    
    // Log files
    out_file: '/var/log/proxmox-dashboard/pm2-out.log',
    error_file: '/var/log/proxmox-dashboard/pm2-error.log',
    log_file: '/var/log/proxmox-dashboard/pm2-combined.log',
    
    // Log rotation
    log_max_size: '10M',
    log_retain: 10,
    
    // Performance monitoring
    pmx: true,
    
    // Advanced settings
    kill_timeout: 5000,
    listen_timeout: 8000,
    
    // Graceful shutdown
    shutdown_with_message: true,
    
    // Source map support
    source_map_support: true,
    
    // Merge logs from all instances
    merge_logs: true,
    
    // Time zone
    time: true
  }]
};

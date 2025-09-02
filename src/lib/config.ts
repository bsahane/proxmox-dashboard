// Application configuration management
// This file handles environment variables and provides defaults

interface AppConfig {
  proxmox: {
    host: string;
    apiTimeout: number;
  };
  guacamole: {
    host: string;
  };
  dashboard: {
    refreshInterval: number;
  };
  security: {
    rejectUnauthorized: boolean;
  };
  app: {
    debugLogging: boolean;
    telemetryDisabled: boolean;
  };
}

// Get configuration from environment variables with defaults
export const config: AppConfig = {
  proxmox: {
    host: process.env.PROXMOX_HOST || 'https://192.168.50.7:8006',
    apiTimeout: parseInt(process.env.PROXMOX_API_TIMEOUT || '30000'),
  },
  guacamole: {
    host: process.env.GUACAMOLE_HOST || 'http://192.168.50.183:8080',
  },
  dashboard: {
    refreshInterval: parseInt(process.env.DASHBOARD_REFRESH_INTERVAL || '30'),
  },
  security: {
    rejectUnauthorized: process.env.NODE_TLS_REJECT_UNAUTHORIZED !== '0',
  },
  app: {
    debugLogging: process.env.DEBUG_LOGGING === 'true',
    telemetryDisabled: process.env.NEXT_TELEMETRY_DISABLED === '1',
  },
};

// Client-side configuration (safe to expose)
export const clientConfig = {
  dashboard: {
    refreshInterval: config.dashboard.refreshInterval,
  },
  app: {
    debugLogging: config.app.debugLogging,
  },
};

// Validation function
export function validateConfig(): { valid: boolean; errors: string[] } {
  const errors: string[] = [];

  // Validate Proxmox host
  try {
    new URL(config.proxmox.host);
  } catch {
    errors.push('PROXMOX_HOST must be a valid URL');
  }

  // Validate Guacamole host
  try {
    new URL(config.guacamole.host);
  } catch {
    errors.push('GUACAMOLE_HOST must be a valid URL');
  }

  // Validate timeout
  if (config.proxmox.apiTimeout < 1000) {
    errors.push('PROXMOX_API_TIMEOUT must be at least 1000ms');
  }

  // Validate refresh interval
  if (config.dashboard.refreshInterval < 5) {
    errors.push('DASHBOARD_REFRESH_INTERVAL must be at least 5 seconds');
  }

  return {
    valid: errors.length === 0,
    errors,
  };
}

// Helper to get Guacamole console URL
export function getGuacamoleConsoleUrl(vmid: number): string {
  return `${config.guacamole.host}/guacamole/#/client/${vmid}`;
}

export default config;

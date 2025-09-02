/** @type {import('next').NextConfig} */
const nextConfig = {
  // Disable Turbopack in container builds for better compatibility
  experimental: {
    // Remove turbopack-specific features that cause issues in containers
  },
  // Standalone output for better container performance
  output: 'standalone',
  // Disable telemetry
  telemetry: {
    disabled: true,
  },
  // Environment variable configuration
  env: {
    NODE_TLS_REJECT_UNAUTHORIZED: process.env.NODE_TLS_REJECT_UNAUTHORIZED || '0',
  },
  // Image optimization for container
  images: {
    unoptimized: true,
  },
  // Disable source maps in production containers
  productionBrowserSourceMaps: false,
  // Rewrites for Proxmox API proxy (same as main config)
  async rewrites() {
    return [
      {
        source: '/api/proxmox/:path*',
        destination: `${process.env.PROXMOX_HOST || 'https://192.168.50.7:8006'}/api2/json/:path*`,
      },
    ];
  },
};

module.exports = nextConfig;

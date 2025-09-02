/** @type {import('next').NextConfig} */
const nextConfig = {
  // Minimal config for container builds - remove ALL problematic options
  output: 'standalone',
  
  // Basic optimizations safe for containers
  images: {
    unoptimized: true,
  },
  
  // No source maps in containers
  productionBrowserSourceMaps: false,
  
  // Basic compiler optimizations
  compiler: {
    removeConsole: process.env.NODE_ENV === 'production',
  },
  
  // Simple rewrites without env references
  async rewrites() {
    return [
      {
        source: '/api/proxmox/:path*',
        destination: 'https://192.168.50.7:8006/api2/json/:path*',
      },
    ];
  },
};

module.exports = nextConfig;

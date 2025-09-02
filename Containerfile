# Proxmox Dashboard - Production Container
# Multi-stage build for optimized production image

# Stage 1: Dependencies and Build
FROM node:18-alpine AS builder

# Set working directory
WORKDIR /app

# Install dependencies needed for building
RUN apk add --no-cache libc6-compat

# Copy package files
COPY package*.json ./

# Install dependencies  
RUN npm ci --omit=dev --silent

# Copy source code
COPY . .

# Set environment variables for build
ENV NODE_ENV=production
ENV NEXT_TELEMETRY_DISABLED=1
ENV NODE_TLS_REJECT_UNAUTHORIZED=0

# Build the application
RUN npm run build

# Stage 2: Production Runtime
FROM node:18-alpine AS runner

# Install runtime dependencies
RUN apk add --no-cache \
    ca-certificates \
    && update-ca-certificates

# Create non-root user for security
RUN addgroup --system --gid 1001 nodejs
RUN adduser --system --uid 1001 nextjs

# Set working directory
WORKDIR /app

# Copy built application from builder stage
COPY --from=builder /app/public ./public
COPY --from=builder --chown=nextjs:nodejs /app/.next/standalone ./
COPY --from=builder --chown=nextjs:nodejs /app/.next/static ./.next/static

# Copy package.json for runtime
COPY --from=builder /app/package.json ./package.json

# Set environment variables
ENV NODE_ENV=production
ENV NEXT_TELEMETRY_DISABLED=1
ENV NODE_TLS_REJECT_UNAUTHORIZED=0
ENV PORT=3000
ENV HOSTNAME=0.0.0.0

# Create logs directory
RUN mkdir -p /app/logs && chown nextjs:nodejs /app/logs

# Switch to non-root user
USER nextjs

# Expose port
EXPOSE 3000

# Health check
HEALTHCHECK --interval=30s --timeout=10s --start-period=5s --retries=3 \
    CMD node -e "require('http').get('http://localhost:3000/api/health', (res) => process.exit(res.statusCode === 200 ? 0 : 1))" || exit 1

# Start the application
CMD ["node", "server.js"]

# Metadata
LABEL maintainer="Proxmox Dashboard Team"
LABEL description="Modern web dashboard for Proxmox VE with Guacamole integration"
LABEL version="1.0.0"
LABEL org.opencontainers.image.title="Proxmox Dashboard"
LABEL org.opencontainers.image.description="A beautiful, modern dashboard for managing Proxmox VMs and LXCs"
LABEL org.opencontainers.image.version="1.0.0"
LABEL org.opencontainers.image.vendor="Proxmox Dashboard Team"

FROM denoland/deno:alpine-1.37.0

# Set working directory
WORKDIR /app

# Copy application files
COPY server.ts .
COPY config.ts .
COPY gallerymd.config.json .
COPY public/ ./public/

# Create cache for dependencies
RUN deno cache server.ts


USER deno

# Expose port
EXPOSE 3000

# Health check
HEALTHCHECK --interval=30s --timeout=3s --start-period=5s --retries=3 \
  CMD deno eval "fetch('http://localhost:3000/api/status').then(r => r.ok ? Deno.exit(0) : Deno.exit(1)).catch(() => Deno.exit(1))"

# Start the server
CMD ["deno", "run", "--allow-net", "--allow-read", "--allow-env", "server.ts"]

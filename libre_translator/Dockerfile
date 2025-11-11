# ============================
# LibreTranslate - Production Dockerfile
# ============================
FROM libretranslate/libretranslate:latest

# Switch temporarily to root to install curl for health checks
USER root

# Install curl and clean up
RUN apt-get update \
    && apt-get install -y --no-install-recommends curl \
    && rm -rf /var/lib/apt/lists/*

# Expose default API port
EXPOSE 5000

# Set environment defaults
ENV LT_SHARED_STORAGE=/data

# Add healthcheck (using curl to verify service readiness)
HEALTHCHECK --interval=30s --timeout=5s --start-period=40s --retries=5 \
    CMD curl -fsS "http://127.0.0.1:${PORT:-5000}/languages" >/dev/null || exit 1

# Switch back to non-root user for security
USER 1000

# Start LibreTranslate (Render injects $PORT automatically)
CMD ["bash", "-lc", "libretranslate --host 0.0.0.0 --port ${PORT:-5000}"]

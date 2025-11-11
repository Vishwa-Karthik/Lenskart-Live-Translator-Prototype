# ============================
# LibreTranslate - Production Dockerfile (Render + Local)
# ============================
FROM libretranslate/libretranslate:latest

# Switch temporarily to root to install curl for healthchecks
USER root

RUN apt-get update \
    && apt-get install -y --no-install-recommends curl \
    && rm -rf /var/lib/apt/lists/*

# Expose default API port
EXPOSE 5000

# Create a writable home directory for the non-root user
RUN mkdir -p /home/libretranslate && chown -R 1000:1000 /home/libretranslate

# Set environment variables
ENV HOME=/home/libretranslate
ENV LT_SHARED_STORAGE=/data
ENV LT_LOAD_ONLY="en,hi"
ENV LT_THREADS="2"

# Healthcheck
HEALTHCHECK --interval=30s --timeout=5s --start-period=40s --retries=5 \
    CMD curl -fsS "http://127.0.0.1:${PORT:-5000}/languages" >/dev/null || exit 1

# Drop back to non-root for security
USER 1000

# Start LibreTranslate (bind to Render’s $PORT or fallback to 5000)
CMD ["bash", "-lc", "libretranslate --host 0.0.0.0 --port ${PORT:-5000}"]

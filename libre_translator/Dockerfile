# ============================
# LibreTranslate - Production Dockerfile
# ============================
FROM libretranslate/libretranslate:latest

# Install curl for healthchecks (small, reliable)
RUN apt-get update \
    && apt-get install -y --no-install-recommends curl \
    && rm -rf /var/lib/apt/lists/*

# Expose default API port (Render will inject $PORT at runtime)
EXPOSE 5000

# Optional, sensible defaults (can be overridden by env at runtime)
# Keep models in a shared path so they persist when you mount a volume
ENV LT_SHARED_STORAGE=/data

# Healthcheck: consider the service healthy if /languages responds
# Render and other orchestrators will use this to decide readiness.
HEALTHCHECK --interval=30s --timeout=5s --start-period=40s --retries=5 \
    CMD curl -fsS "http://127.0.0.1:${PORT:-5000}/languages" >/dev/null || exit 1

# Start LibreTranslate:
# - Bind to all interfaces
# - Respect $PORT if provided (Render), default to 5000 locally
# Other LT_* env (e.g., LT_LOAD_ONLY, LT_DEBUG, LT_THREADS, etc.) are
# read by the upstream image and applied automatically.
CMD ["bash", "-lc", "libretranslate --host 0.0.0.0 --port ${PORT:-5000}"]

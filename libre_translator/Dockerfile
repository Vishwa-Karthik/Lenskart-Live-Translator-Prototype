# Use official LibreTranslate base image
FROM libretranslate/libretranslate:latest

# Railway will set PORT env variable. Default to 5000 locally.
ENV PORT=5000

# Ensure the server binds correctly on Railway (0.0.0.0)
ENV LT_PORT=${PORT}
ENV LT_HOST=0.0.0.0

# Optional tuning (safe defaults)
ENV LT_UPDATE_MODELS=true
ENV LT_LOAD_ONLY=en,es,fr,hi

# Expose the dynamic port (Railway auto-detects)
EXPOSE ${PORT}

# Start LibreTranslate with dynamic port
CMD ["bash", "-c", "libretranslate --host $LT_HOST --port $PORT"]

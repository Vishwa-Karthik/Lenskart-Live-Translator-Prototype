# ============================
# LibreTranslate Dockerfile
# ============================
FROM libretranslate/libretranslate:latest

# Expose API port
EXPOSE 5000

# (Optional) pre-download some models to make first request faster
# Uncomment for Hindi / Kannada / English
# RUN libretranslate --load-only en hi kn

# Default startup command
CMD ["libretranslate"]

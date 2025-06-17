# ────────────────────────────────────────────────────────────────
# GIANT-UI container for MACOS
# ────────────────────────────────────────────────────────────────
FROM --platform=linux/arm64 python:3.11-slim

# System deps (none, but keep layer for later)
RUN apt-get update && apt-get install -y --no-install-recommends \
    && rm -rf /var/lib/apt/lists/*

# ── Python layer ────────────────────────────────────────────────
WORKDIR /app
COPY SUPER-GIANT/UI/requirements.txt .
RUN pip install --no-cache-dir -r requirements.txt

# ── App code ────────────────────────────────────────────────────
COPY SUPER-GIANT/UI/ .

# Default target if the caller forgets to provide one
ENV GIANT_API=http://localhost:8000

EXPOSE 5001

# One-liner: gunicorn, 2 workers, binds 0.0.0.0:5001
CMD ["python", "ui/app.py"]

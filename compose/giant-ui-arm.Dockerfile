# ────────────────────────────────────────────────────────────────
# GIANT-UI container
# Python 3.11 on Debian slim, ARM64 and AMD64 compatible
# ────────────────────────────────────────────────────────────────
FROM --platform=linux/arm64 python:3.11-slim

ENV DEBIAN_FRONTEND=noninteractive

# ── System packages ─────────────────────────────────────────────
RUN apt-get update \
 && apt-get install -y --no-install-recommends \
        dumb-init \
 && rm -rf /var/lib/apt/lists/*

# ── Create and use workspace ────────────────────────────────────
WORKDIR /workspace/SUPER-GIANT/UI

# ── Python dependencies ─────────────────────────────────────────
# Copy just requirements first to leverage Docker cache
COPY SUPER-GIANT/UI/requirements.txt ./requirements.txt
RUN pip install --upgrade pip \
 && pip install --no-cache-dir -r requirements.txt

# ── Application code ────────────────────────────────────────────
COPY SUPER-GIANT/UI/ .

# ── Runtime configuration ───────────────────────────────────────
# Points your UI at the CORE API by default; override at runtime if needed
ENV GIANT_API=http://localhost:8000

EXPOSE 5001

# ── Entrypoint & CMD ────────────────────────────────────────────
ENTRYPOINT ["/usr/bin/dumb-init", "--"]
CMD ["python", "app.py"]


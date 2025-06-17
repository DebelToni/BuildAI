FROM --platform=linux/arm64 python:3.11-slim

ENV DEBIAN_FRONTEND=noninteractive

# ── System packages ─────────────────────────────────────────────
RUN apt-get update \
 && apt-get install -y --no-install-recommends \
        dumb-init \
 && rm -rf /var/lib/apt/lists/*

# ── Create and use workspace ────────────────────────────────────
WORKDIR /workspace/LADA

# ── Python dependencies ─────────────────────────────────────────
# Copy requirements first so Docker cache is leveraged
COPY LADA/requirements.txt ./requirements.txt
RUN pip install --upgrade pip \
 && pip install --no-cache-dir -r requirements.txt

# ── Application code ────────────────────────────────────────────
COPY LADA/ .

# ── Runtime configuration ───────────────────────────────────────
EXPOSE 5000

# ── Entrypoint & CMD ────────────────────────────────────────────
ENTRYPOINT ["/usr/bin/dumb-init", "--"]
CMD ["python", "app.py"]


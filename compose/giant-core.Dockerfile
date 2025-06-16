# ────────────────────────────────────────────────────────────────────────────────
# SUPER-GIANT - training container
# CUDA 12.9 + cuDNN + Python 3.11 + JAX
# with OpenSSH server (root / key-only)
# ────────────────────────────────────────────────────────────────────────────────
FROM nvidia/cuda:12.9.0-cudnn-runtime-ubuntu22.04

ENV DEBIAN_FRONTEND=noninteractive

# ── System packages + OpenSSH ───────────────────────────────────────────────────
RUN apt-get update && apt-get install -y --no-install-recommends \
        build-essential git wget curl ca-certificates vim pkg-config \
        python3.11 python3.11-venv python3-pip                       \
        libssl-dev zlib1g-dev libbz2-dev libreadline-dev             \
        libsqlite3-dev libffi-dev liblzma-dev tk-dev uuid-dev        \
        openssh-server                                               \
    && rm -rf /var/lib/apt/lists/*

# ── Python virtual environment ──────────────────────────────────────────────────
ENV VENV_DIR=/opt/venv
RUN python3.11 -m venv $VENV_DIR
ENV PATH="$VENV_DIR/bin:$PATH" \
    VIRTUAL_ENV=$VENV_DIR

# ── Python dependencies (from repo’s requirements.txt) ──────────────────────────
COPY SUPER-GIANT/requirements.txt /tmp/requirements.txt
RUN ls -l /tmp && cat /tmp/requirements.txt
RUN pip install --upgrade pip && \
    pip install --no-cache-dir -r /tmp/requirements.txt
# clean up
RUN rm /tmp/requirements.txt

# ── SSH configuration ───────────────────────────────────────────────────────────
RUN mkdir /var/run/sshd && \
    mkdir -p /root/.ssh && chmod 700 /root/.ssh && \
    sed -i 's/#PermitRootLogin prohibit-password/PermitRootLogin yes/' /etc/ssh/sshd_config && \
    sed -i 's/#PasswordAuthentication yes/PasswordAuthentication no/'  /etc/ssh/sshd_config

COPY SUPER-GIANT/giant-training/id_rsa.pub /root/.ssh/authorized_keys
RUN chmod 600 /root/.ssh/authorized_keys

EXPOSE 22

# ── Project workspace ───────────────────────────────────────────────────────────
WORKDIR /workspace/SUPER-GIANT
COPY ./SUPER-GIANT /workspace/SUPER-GIANT

# ── Entrypoint ──────────────────────────────────────────────────────────────────
# Starts the SSH daemon in the foreground.
# Override in docker-compose or `docker run … CMD` if you want to launch training
CMD ["/usr/sbin/sshd","-D"]


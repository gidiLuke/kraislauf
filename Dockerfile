# syntax=docker/dockerfile:1

# === Python Builder Stage ===
FROM ghcr.io/astral-sh/uv:python3.13-bookworm-slim AS builder
WORKDIR /app

# Install Python dependencies
ENV UV_LINK_MODE=copy
COPY backend/pyproject.toml uv.loc[k] ./backend/
RUN cd backend && \
    if [ -f "uv.lock" ]; then \
    uv sync --no-install-project --locked && uv cache prune --ci; \
    else \
    uv sync && uv cache prune --ci; \
    fi

# === Development IDE Stage ===
FROM builder AS ide
USER root

# Install system dependencies
RUN apt-get update \
    && apt-get install -y curl gnupg ca-certificates git wget \
    && rm -rf /var/lib/apt/lists/*

# Install GitHub CLI
RUN mkdir -p -m 755 /etc/apt/keyrings \
    && wget -nv -O- https://cli.github.com/packages/githubcli-archive-keyring.gpg | tee /etc/apt/keyrings/githubcli-archive-keyring.gpg > /dev/null \
    && chmod go+r /etc/apt/keyrings/githubcli-archive-keyring.gpg \
    && echo "deb [arch=$(dpkg --print-architecture) signed-by=/etc/apt/keyrings/githubcli-archive-keyring.gpg] https://cli.github.com/packages stable main" | tee /etc/apt/sources.list.d/github-cli.list > /dev/null \
    && apt-get update \
    && apt-get install -y gh \
    && rm -rf /var/lib/apt/lists/*

# Install Node.js
RUN curl -fsSL https://deb.nodesource.com/setup_20.x | bash - \
    && apt-get update \
    && apt-get install -y nodejs

# Install package managers and tools
RUN curl -fsSL https://get.pnpm.io/install.sh | SHELL=/bin/bash sh - && \
    export PNPM_HOME="/root/.local/share/pnpm" && \
    export PATH="$PNPM_HOME:$PATH" && \
    echo 'export PNPM_HOME="/root/.local/share/pnpm"' >> /root/.bashrc && \
    echo 'export PATH="$PNPM_HOME:$PATH"' >> /root/.bashrc
RUN curl -fsSL https://get.opentofu.org/install.sh | sh -s -- \
    --install-method standalone \
    --install-path /usr/local/bin

# Setup frontend
COPY frontend/package.json frontend/pnpm-lock.yam[l] ./frontend/
RUN cd frontend && \
    export PNPM_HOME="/root/.local/share/pnpm" && \
    export PATH="$PNPM_HOME:$PATH" && \
    if [ -f "pnpm-lock.yaml" ]; then \
    pnpm install --frozen-lockfile; \
    else \
    pnpm install; \
    fi

# === Production Runtime Stage ===
FROM python:3.13-slim-bookworm AS runtime
WORKDIR /app

# Copy Python environment and application code
COPY --from=builder /app/backend/.venv /opt/venv
COPY --from=builder /app/backend ./

# Configure environment
ENV PATH="/opt/venv/bin:$PATH"
EXPOSE 80

# Start application
CMD ["uv", "run", "uvicorn", "main:app", "--host", "0.0.0.0", "--port", "80"]

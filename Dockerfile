# Multi-stage Dockerfile for kraislauf project
# syntax=docker/dockerfile:1

# ===================================================
# Base Stage with common dependencies for all stages
# ===================================================
FROM ghcr.io/astral-sh/uv:python3.13-bookworm-slim AS base
WORKDIR /app

# Install essential system packages
RUN apt-get update && apt-get install -y \
    curl wget gnupg ca-certificates lsb-release \
    && rm -rf /var/lib/apt/lists/*

# ===================================================
# Python Dependencies Stage
# ===================================================
FROM base AS python-deps
WORKDIR /app

# Install Python dependencies using uv directly to system Python
ENV UV_LINK_MODE=copy
# Use the system Python environment instead of a virtual environment
ENV UV_PROJECT_ENVIRONMENT="/usr/local/"

# using the [k] pattern makes the command succeed even if uv.lock is not present
COPY backend/pyproject.toml backend/uv.loc[k] ./backend/
RUN cd backend && \
    if [ -f "uv.lock" ]; then \
    uv sync --frozen --no-install-project --no-cache; \
    else \
    uv sync --no-install-project --no-cache; \
    fi

# ===================================================
# Node.js Dependencies Stage
# ===================================================
FROM base AS node-deps
WORKDIR /app

# Install Node.js
RUN curl -fsSL https://deb.nodesource.com/setup_20.x | bash - \
    && apt-get update \
    && apt-get install -y nodejs \
    && rm -rf /var/lib/apt/lists/*

# Install pnpm
RUN curl -fsSL https://get.pnpm.io/install.sh | SHELL=/bin/bash sh - \
    && export PNPM_HOME="/root/.local/share/pnpm" \
    && export PATH="$PNPM_HOME:$PATH"

# Copy frontend package files and install dependencies to a global location
# Using [l] pattern to succeed even if pnpm-lock.yaml is not present
COPY frontend/package.json frontend/pnpm-lock.yam[l] ./frontend/
RUN mkdir -p /opt/pnpm-store && \
    cd frontend && \
    export PNPM_HOME="/root/.local/share/pnpm" && \
    export PATH="$PNPM_HOME:$PATH" && \
    if [ -f "pnpm-lock.yaml" ]; then \
    pnpm install --frozen-lockfile --store-dir=/opt/pnpm-store; \
    else \
    pnpm install --store-dir=/opt/pnpm-store; \
    fi

# ===================================================
# Development IDE Stage
# ===================================================
FROM base AS ide
USER root

# Install additional development tools
RUN apt-get update && apt-get install -y \
    sudo jq unzip gcc git g++ zsh apt-transport-https vim \
    && rm -rf /var/lib/apt/lists/*

# Set up zsh with Oh My Zsh
RUN sh -c "$(curl -fsSL https://raw.githubusercontent.com/ohmyzsh/ohmyzsh/master/tools/install.sh)" "" --unattended

# Install Azure CLI
RUN curl -sL https://aka.ms/InstallAzureCLIDeb | bash

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
    && apt-get install -y nodejs \
    && npm install -g npm@latest \
    && rm -rf /var/lib/apt/lists/*

# Install pnpm
RUN curl -fsSL https://get.pnpm.io/install.sh | SHELL=/bin/bash sh - \
    && export PNPM_HOME="/root/.local/share/pnpm" \
    && export PATH="$PNPM_HOME:$PATH" \
    && echo 'export PNPM_HOME="/root/.local/share/pnpm"' >> /root/.bashrc \
    && echo 'export PATH="$PNPM_HOME:$PATH"' >> /root/.bashrc

# Install OpenTofu
RUN curl --proto '=https' --tlsv1.2 -fsSL https://get.opentofu.org/install-opentofu.sh -o install-opentofu.sh && \
    chmod +x install-opentofu.sh && \
    ./install-opentofu.sh --install-method standalone

# Create a non-root user
RUN groupadd --gid 1000 vscode \
    && useradd --uid 1000 --gid 1000 -m vscode \
    && echo "vscode ALL=(ALL) NOPASSWD:ALL" > /etc/sudoers.d/vscode \
    && chmod 0440 /etc/sudoers.d/vscode \
    && mkdir -p /home/vscode/.vscode-server \
    && chown -R vscode:vscode /home/vscode \
    && chsh -s /usr/bin/zsh vscode

# Install Python development tools
ENV UV_LINK_MODE=copy
ENV UV_PROJECT_ENVIRONMENT="/usr/local/"
# Install dev dependencies
COPY backend/pyproject.toml backend/uv.loc[k] ./backend/
RUN cd backend && \
    if [ -f "uv.lock" ]; then \
    uv sync --frozen --no-install-project --no-cache; \
    else \
    uv sync --no-install-project --no-cache; \
    fi

# Install frontend development tools
RUN npm install -g tailwindcss@latest postcss@latest autoprefixer@latest typescript@latest

# Copy Python dependencies from python-deps stage to system Python
COPY --from=python-deps /usr/local/ /usr/local/
ENV PYTHONPATH="/home/vscode/app/backend"

# Copy frontend dependencies to global location
COPY --from=node-deps /opt/pnpm-store /opt/pnpm-store
COPY --from=node-deps /root/.local/share/pnpm /opt/pnpm-global

# Set up environment variables
ENV PYTHONPATH="/app/backend"

# Configure zsh
RUN echo 'export PYTHONPATH="/home/vscode/app/backend"' >> /home/vscode/.zshrc && \
    echo 'export PATH="$HOME/.local/bin:$PATH"' >> /home/vscode/.zshrc && \
    echo 'export PNPM_HOME="$HOME/.local/share/pnpm"' >> /home/vscode/.zshrc && \
    echo 'if [ ! -d "$PNPM_HOME" ] && [ -d "/opt/pnpm-global" ]; then mkdir -p "$PNPM_HOME" && cp -R /opt/pnpm-global/* "$PNPM_HOME/"; fi' >> /home/vscode/.zshrc && \
    echo 'export PATH="$PNPM_HOME:$PATH"' >> /home/vscode/.zshrc

# Switch to non-root user for development
USER vscode
WORKDIR /home/vscode/app

# Install pnpm for vscode user
RUN curl -fsSL https://get.pnpm.io/install.sh | SHELL=/bin/bash sh - && \
    mkdir -p $HOME/.local/share/pnpm && \
    echo 'export PNPM_HOME="$HOME/.local/share/pnpm"' >> $HOME/.bashrc && \
    echo 'export PATH="$PNPM_HOME:$PATH"' >> $HOME/.bashrc

# ===================================================
# CI/CD Testing & Linting Stage
# ===================================================
FROM base AS ci
WORKDIR /app

# Install necessary tools for CI
RUN apt-get update && apt-get install -y \
    nodejs npm \
    && rm -rf /var/lib/apt/lists/*

# Install pnpm
RUN curl -fsSL https://get.pnpm.io/install.sh | SHELL=/bin/bash sh - \
    && export PNPM_HOME="/root/.local/share/pnpm" \
    && export PATH="$PNPM_HOME:$PATH"

# Install Python testing tools
ENV UV_LINK_MODE=copy
ENV UV_PROJECT_ENVIRONMENT="/usr/local/"

# Copy Python dependencies from python-deps stage
COPY --from=python-deps /usr/local/ /usr/local/
ENV PYTHONPATH="/app/backend"

# ===================================================
# Frontend Build Stage
# ===================================================
FROM node-deps AS frontend-build
WORKDIR /app

# Copy frontend code
COPY frontend/ ./frontend/

# Build frontend
RUN cd frontend && \
    export PNPM_HOME="/root/.local/share/pnpm" && \
    export PATH="$PNPM_HOME:$PATH" && \
    pnpm build

# ===================================================
# Backend Runtime Stage
# ===================================================
FROM python:3.13-slim-bookworm AS runtime
WORKDIR /app

# Copy Python dependencies from python-deps stage
COPY --from=python-deps /usr/local/ /usr/local/
COPY backend/ ./

# Configure environment
ENV PYTHONPATH="/app"
EXPOSE 80

# Set healthcheck
HEALTHCHECK --interval=30s --timeout=30s --start-period=5s --retries=3 \
    CMD curl -f http://localhost:80/health || exit 1

# Start application
CMD ["uvicorn", "app.main:app", "--host", "0.0.0.0", "--port", "80"]

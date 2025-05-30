#!/bin/bash
# Setup custom zsh prompt and other zsh configurations

# Ensure the file exists with proper permissions
touch /home/vscode/.zshrc
chown vscode:vscode /home/vscode/.zshrc

# Add the existing environment variables
cat > /home/vscode/.zshrc << 'EOF'
export PYTHONPATH="/home/vscode/app/backend"
export PATH="$HOME/.local/bin:$PATH"
export PNPM_HOME="$HOME/.local/share/pnpm"
if [ ! -d "$PNPM_HOME" ] && [ -d "/opt/pnpm-global" ]; then mkdir -p "$PNPM_HOME" && cp -R /opt/pnpm-global/* "$PNPM_HOME/"; fi
export PATH="$PNPM_HOME:$PATH"

# Set a custom prompt with current directory path
PROMPT="%F{green}%n%f:%F{blue}%~%f$ "
EOF

# Ensure proper permissions
chown vscode:vscode /home/vscode/.zshrc

#!/usr/bin/env bash
# Workspace startup script for kiro-crew-prototype-a
# Runs as the coder user (uid 1000) inside the workspace container.
set -e

# ── SSH known hosts ────────────────────────────────────────────────────────────
mkdir -p ~/.ssh
ssh-keyscan -t ed25519,rsa github.com >> ~/.ssh/known_hosts 2>/dev/null
chmod 700 ~/.ssh
chmod 600 ~/.ssh/known_hosts

# ── Persistent bin directories ─────────────────────────────────────────────────
mkdir -p $HOME/bin
mkdir -p $HOME/.local/bin

# ── PATH for current session ───────────────────────────────────────────────────
export PATH="$HOME/.local/bin:$HOME/bin:$HOME/.npm-global/bin:$PATH"

sudo apt-get update -qq

# ── Core utilities ─────────────────────────────────────────────────────────────
# curl, unzip, openssl, sha256sum: required by both kiro-cli and kirocrew
# install scripts (kirocrew verifies its signed manifest with openssl + sha256sum).
sudo apt-get install -y \
  curl \
  unzip \
  gnupg \
  dirmngr \
  openssl \
  ca-certificates

# ── Python 3.11 runtime for KiroCrew ──────────────────────────────────────────
# The base codercom/enterprise-base:ubuntu image ships Python 3.10 as the
# default python3. KiroCrew's install script (cli.sh) creates a managed venv
# at ~/.kiro/crew-venv using python3.11 (the preferred interpreter per the
# installer's resolver: python3.12 > python3.11 > python3.10).
#
# Required packages:
#   python3.11        — interpreter (may already be present on Ubuntu 22.04)
#   python3.11-venv   — ensurepip + venv module (split package on Debian/Ubuntu)
#   python3.11-dev    — headers needed if any pip packages compile native exts
#   python3-pip       — bootstrap pip for the system python3
#
# Note: the llama-cpp-python bundled inside kiro_crew._vendor logs a WARNING
# about "Shared library with base name 'llama' not found" on every gateway
# start. This is expected — KiroCrew ships the Python wrapper but NOT the
# compiled libllama.so. The gateway falls back to API-based embeddings. Cosmetic only.
# The cgroup v2 warning about XDG_RUNTIME_DIR is also expected in Kubernetes.
if ! python3.11 --version &>/dev/null; then
  echo "Installing Python 3.11 from deadsnakes PPA..."
  sudo apt-get install -y software-properties-common
  sudo add-apt-repository -y ppa:deadsnakes/ppa
  sudo apt-get update -qq
fi
sudo apt-get install -y \
  python3.11 \
  python3.11-venv \
  python3.11-dev \
  python3-pip

# ── AWS CLI ────────────────────────────────────────────────────────────────────
if ! command -v aws &>/dev/null; then
  echo "Installing AWS CLI..."
  cd $HOME
  curl "https://awscli.amazonaws.com/awscli-exe-linux-x86_64.zip" -o "awscliv2.zip"
  unzip -q awscliv2.zip
  ./aws/install --install-dir $HOME/.local/aws-cli --bin-dir $HOME/.local/bin
  aws --version
  rm -rf aws awscliv2.zip
  echo "AWS CLI installation completed"
else
  echo "AWS CLI already installed: $(aws --version)"
fi

# ── Node.js 20 LTS ────────────────────────────────────────────────────────────
if ! command -v node &>/dev/null; then
  echo "Installing Node.js 20..."
  curl -fsSL https://deb.nodesource.com/setup_20.x | sudo -E bash -
  sudo apt-get install -y nodejs
  node -v && npm -v
  echo "Node.js installation completed"
else
  echo "Node.js already installed: $(node -v)"
fi

# ── AWS CDK ────────────────────────────────────────────────────────────────────
if ! command -v cdk &>/dev/null; then
  echo "Installing AWS CDK..."
  mkdir -p $HOME/.npm-global
  npm config set prefix "$HOME/.npm-global"
  npm install -g aws-cdk
  ln -sf $HOME/.npm-global/bin/cdk $HOME/.local/bin/cdk
  cdk --version
  echo "AWS CDK installation completed"
else
  echo "AWS CDK already installed: $(cdk --version)"
fi

# ── Kiro CLI ───────────────────────────────────────────────────────────────────
if ! command -v kiro-cli &>/dev/null; then
  echo "Installing Kiro CLI..."
  curl -fsSL https://cli.kiro.dev/install | bash
  kiro-cli version
  echo "Kiro CLI installation completed"
else
  echo "Kiro CLI already installed: $(kiro-cli version 2>/dev/null || echo 'unknown')"
fi

# ── KiroCrew ──────────────────────────────────────────────────────────────────
# IMPORTANT: unset PYTHONPATH/PYTHONHOME before calling the installer.
# Inherited values cause pip to treat foreign packages as already-satisfied,
# silently skipping kirocrew's deps → ImportError: No module named 'aiohttp'.
if ! command -v kirocrew &>/dev/null && [ ! -x "$HOME/.kiro/crew-venv/bin/kirocrew" ]; then
  echo "Installing KiroCrew..."
  unset PYTHONPATH PYTHONHOME
  curl -fsSL https://download.crew.kiro.dev/cli.sh | sh
  echo "KiroCrew installation completed"
else
  echo "KiroCrew already installed"
fi

# ── uv / uvx (Python MCP servers) ─────────────────────────────────────────────
if [ ! -f "$HOME/.local/bin/uv" ]; then
  echo "Installing uv/uvx..."
  unset PYTHONPATH PYTHONHOME
  UV_UNMANAGED_INSTALL="$HOME/.local/bin" curl -LsSf https://astral.sh/uv/install.sh | sh
  echo "uv/uvx installation completed"
else
  echo "uv/uvx already installed"
fi

# ── Coder MCP server configuration ────────────────────────────────────────────
echo "Configuring Kiro CLI MCP servers..."
mkdir -p $HOME/.kiro/settings

CODER_URL_CLEAN="${CODER_URL%/}"
CODER_MCP_URL="${CODER_URL_CLEAN}/api/experimental/mcp/http"

cat > ~/.kiro/settings/mcp.json <<EOF
{
  "mcpServers": {
    "coder": {
      "url": "$CODER_MCP_URL",
      "headers": {
        "Authorization": "Bearer $CODER_SESSION_TOKEN"
      },
      "autoApprove": [
        "coder_workspace_edit_file",
        "coder_workspace_read_file",
        "coder_get_task_status",
        "coder_workspace_write_file",
        "coder_workspace_ls",
        "coder_workspace_bash",
        "coder_get_task_logs",
        "coder_list_templates",
        "coder_create_task",
        "coder_get_authenticated_user",
        "coder_delete_task",
        "coder_send_task_input",
        "coder_list_workspaces",
        "coder_workspace_edit_files",
        "coder_workspace_list_apps",
        "coder_workspace_port_forward",
        "coder_create_workspace_build",
        "coder_template_version_parameters"
      ]
    }
  }
}
EOF

echo "MCP configuration completed"

# ── Workspace trust (Kiro IDE) ─────────────────────────────────────────────────
echo "Configuring Kiro IDE workspace trust..."
mkdir -p $HOME/.local/share/code-server/User

cat > $HOME/.local/share/code-server/User/settings.json <<'SETTINGS_EOF'
{
  "security.workspace.trust.enabled": true,
  "security.workspace.trust.startupPrompt": "never",
  "security.workspace.trust.emptyWindow": false,
  "security.workspace.trust.untrustedFiles": "open"
}
SETTINGS_EOF

mkdir -p $HOME/.kiro/settings
cat > $HOME/.kiro/settings/trusted-workspaces.json <<'TRUST_EOF'
{
  "trustedFolders": [
    "/home/coder"
  ]
}
TRUST_EOF

echo "Workspace trust configuration completed"

# ── Coder agent binary symlink ─────────────────────────────────────────────────
ln -sf /tmp/coder.*/coder "$CODER_SCRIPT_BIN_DIR/coder"

#!/usr/bin/env bash
# KiroCrew Gateway – install (if needed) and start the KiroCrew daemon.
# Variables are injected by Terraform templatefile().
#
# System requirements (must be pre-installed by the workspace startup_script):
#   - curl, openssl, sha256sum  (for cli.sh manifest signature verification)
#   - python3.11 + python3.11-venv  (kirocrew's managed venv; >=3.10 required,
#     3.11 preferred as it is the tested release target)
#
# Known warnings that are expected and non-fatal:
#   - "Vendored llama-cpp-python failed to import" — kirocrew ships the Python
#     wrapper for llama.cpp but NOT the compiled libllama.so. The gateway falls
#     back to API-based embeddings automatically. No fix is needed.
#   - "cgroup v2 scope enforcement unavailable (no XDG_RUNTIME_DIR)" — Kubernetes
#     containers don't run a systemd user session, so sandbox memory/CPU cgroup
#     enforcement is unavailable. RLIMIT_NOFILE still applies. Non-fatal.

set -euo pipefail

BOLD='\033[0;1m'
RESET='\033[0m'

INSTALL_PREFIX="${INSTALL_PREFIX}"
PORT="${PORT}"
LOG_PATH="${LOG_PATH}"
USE_CACHED="${USE_CACHED}"
EXTRA_MCP_B64='${EXTRA_MCP_B64}'
AWS_TOKEN_B64='${AWS_TOKEN_B64}'
ALLOWED_ORIGINS='${ALLOWED_ORIGINS}'

export PATH="$INSTALL_PREFIX:$HOME/.local/bin:$HOME/bin:$PATH"

# ── Install Kiro CLI ──────────────────────────────────────────────────────────

if [ "$USE_CACHED" = "true" ] && command -v kiro-cli &>/dev/null; then
  echo "✓ kiro-cli already installed: $(kiro-cli version 2>/dev/null || echo 'unknown')"
else
  echo -e "$${BOLD}Installing Kiro CLI...$${RESET}"
  curl -fsSL https://cli.kiro.dev/install | bash
  echo "✓ Kiro CLI installed"
fi

# ── Install KiroCrew ─────────────────────────────────────────────────────────
# IMPORTANT: unset PYTHONPATH/PYTHONHOME before calling cli.sh.
# The Coder agent environment may inherit these from other tools, which causes
# pip to treat foreign packages as already-satisfied and silently skip installing
# kirocrew's dependencies into the managed venv — producing a broken install
# (ImportError: No module named 'aiohttp' on first gateway start).

KIROCREW_VENV_BIN="$HOME/.kiro/crew-venv/bin/kirocrew"
if [ "$USE_CACHED" = "true" ] && command -v kirocrew &>/dev/null; then
  echo "✓ kirocrew already installed (in PATH)"
elif [ "$USE_CACHED" = "true" ] && [ -x "$KIROCREW_VENV_BIN" ]; then
  echo "✓ kirocrew already installed at $KIROCREW_VENV_BIN"
else
  echo -e "$${BOLD}Installing KiroCrew...$${RESET}"
  unset PYTHONPATH PYTHONHOME
  curl -fsSL https://download.crew.kiro.dev/cli.sh | sh
  echo "✓ KiroCrew installed"
fi

# ── Optional: inject extra MCP JSON ──────────────────────────────────────────

if [ -n "$EXTRA_MCP_B64" ]; then
  echo "Applying extra MCP configuration..."
  mkdir -p "$HOME/.kiro/settings"

  EXTRA_MCP_JSON="$(echo -n "$EXTRA_MCP_B64" | base64 -d)"

  if [ -f "$HOME/.kiro/settings/mcp.json" ] && command -v python3 &>/dev/null; then
    # Deep-merge: existing keys win, new keys are added
    python3 - "$HOME/.kiro/settings/mcp.json" "$EXTRA_MCP_JSON" <<'PYEOF'
import json, sys
existing = json.load(open(sys.argv[1]))
new      = json.loads(sys.argv[2])
def merge(a, b):
    for k, v in b.items():
        if k in a and isinstance(a[k], dict) and isinstance(v, dict):
            merge(a[k], v)
        else:
            a[k] = v
merge(existing, new)
open(sys.argv[1], "w").write(json.dumps(existing, indent=2))
PYEOF
    echo "  MCP config merged."
  else
    mkdir -p "$HOME/.kiro/settings"
    echo -n "$EXTRA_MCP_B64" | base64 -d > "$HOME/.kiro/settings/mcp.json"
    echo "  MCP config written."
  fi
fi

# ── Optional: expose AWS Builder ID token as env ──────────────────────────────
# The token is decoded and written to a temp file that kiro-cli / kirocrew
# can source at start-up to authenticate against AWS Builder ID without
# interactive prompts.

if [ -n "$AWS_TOKEN_B64" ]; then
  echo "Configuring AWS Builder ID token..."
  AWS_TOKEN="$(echo -n "$AWS_TOKEN_B64" | base64 -d)"
  mkdir -p "$HOME/.kiro"
  # Write a small shell snippet sourced by the gateway launcher below
  cat > "$HOME/.kiro/.aws-builder-id-env" <<EOF
export KIRO_AWS_BUILDER_ID_TOKEN="$AWS_TOKEN"
EOF
  chmod 600 "$HOME/.kiro/.aws-builder-id-env"
  echo "  AWS Builder ID token staged."
fi

# ── Free the port if a stale gateway is bound to it ───────────────────────────
# Everything from here on is best-effort and must NOT abort the script before it
# reaches the launch step, so disable errexit for the remainder.
set +e

# Target a stale gateway by its LISTENING SOCKET / port, NEVER by
# `pkill -f <pattern>`. The Coder agent runs this coder_script inline
# (bash -c "<full script text>"), so the script's own process argv contains the
# words "kirocrew" and the port number. A pattern like "kirocrew.*PORT" then
# matches — and SIGTERMs — THIS very script, right after the install checks
# (agent logs "signal: terminated", gateway never launches). Port-based killing
# cannot hit ourselves.
if command -v fuser >/dev/null 2>&1; then
  fuser -k "${PORT}/tcp" >/dev/null 2>&1 || true
else
  port_pid="$(ss -ltnHp "sport = :${PORT}" 2>/dev/null | grep -oE 'pid=[0-9]+' | head -1 | cut -d= -f2)"
  if [ -n "$port_pid" ] && [ "$port_pid" != "$$" ] && [ "$port_pid" != "$PPID" ]; then
    kill "$port_pid" >/dev/null 2>&1 || true
  fi
fi

# ── Resolve kirocrew binary ───────────────────────────────────────────────────
# The installer places kirocrew in ~/.kiro/crew-venv/bin/ and wires it into
# PATH via ~/.local/bin or similar. Fall back to the venv path explicitly.

KIROCREW_CMD=""
if command -v kirocrew &>/dev/null; then
  KIROCREW_CMD="$(command -v kirocrew)"
elif [ -x "$HOME/.kiro/crew-venv/bin/kirocrew" ]; then
  KIROCREW_CMD="$HOME/.kiro/crew-venv/bin/kirocrew"
else
  echo "ERROR: kirocrew binary not found. Check installation logs."
  exit 1
fi

# ── Launch KiroCrew gateway (fully decoupled from this script) ────────────────
# This coder_script MUST return quickly. The Coder agent SIGTERMs a start script
# that runs too long, and observed behaviour is that a slow gateway cold-start
# (Python import + retrying sandbox probes) under parallel-boot memory pressure
# pushes an in-script health-wait past that budget — the agent then kills the
# script AND the gateway starting under it ("gateway exited on startup").
#
# So we do NOT wait here. We write a self-contained launcher and hand it to a
# fully detached session (setsid + nohup, own std fds), then return immediately.
# The KiroCrew coder_app healthcheck polls /health to surface readiness.
#
# The launcher also performs the sandbox/userns decision at gateway-start time:
# KiroCrew isolates every agent subprocess with a Linux user namespace
# (unshare(CLONE_NEWUSER)); Coder K8s pods commonly set user.max_user_namespaces=0,
# making the OS sandbox impossible. When userns is unavailable we allow
# unsandboxed exec (the pod is the per-user isolation boundary); where userns
# works, the sandbox stays enabled.

echo "Dispatching KiroCrew gateway launcher (detached) on port ${PORT}"
echo "Logs at: ${LOG_PATH}"
echo "Using kirocrew binary: $KIROCREW_CMD"
: > "${LOG_PATH}" 2>/dev/null || true

LAUNCHER_PATH="$HOME/.kiro/crew/start-gateway.sh"
mkdir -p "$HOME/.kiro/crew"

# Quoted heredoc: nothing is expanded at write time. Values are passed via env
# (KC_CMD/KC_PORT) at launch, so the launcher stays free of template/quote traps.
cat > "$LAUNCHER_PATH" <<'LAUNCHER'
#!/usr/bin/env bash
[ -f "$HOME/.kiro/.aws-builder-id-env" ] && source "$HOME/.kiro/.aws-builder-id-env"
# Trust the Coder proxy host(s) in the gateway's Host/Origin allowlist so the
# dashboard is reachable through Coder ("Host header not allowed." otherwise).
[ -n "$KC_ORIGINS" ] && export KIROCREW_CORS_ORIGINS="$KC_ORIGINS"
if ! unshare --user --map-root-user true >/dev/null 2>&1; then
  "$KC_CMD" config set agent.sandbox_allow_unsandboxed_exec true >/dev/null 2>&1 || true
fi
exec env KIROCREW_PORT="$KC_PORT" "$KC_CMD" gateway
LAUNCHER
chmod +x "$LAUNCHER_PATH"

setsid nohup env KC_CMD="$KIROCREW_CMD" KC_PORT="${PORT}" KC_ORIGINS="${ALLOWED_ORIGINS}" \
  bash "$LAUNCHER_PATH" >> "${LOG_PATH}" 2>&1 < /dev/null &
disown 2>/dev/null || true

echo "✓ KiroCrew gateway launch dispatched; readiness is surfaced by the KiroCrew app healthcheck."

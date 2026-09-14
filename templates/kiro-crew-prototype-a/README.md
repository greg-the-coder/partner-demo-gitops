---
display_name: Kiro Crew (Prototype A) on Kubernetes
description: Runs the Kiro Crew gateway and web dashboard inside a Coder Kubernetes workspace, with Kiro CLI pre-installed and the dashboard published through the Coder Workspace Proxy.
icon: ../../../site/static/icon/k8s.png
maintainer_github: coder
verified: true
tags: [kubernetes, container, kiro, kirocrew, aws, mcp, ai]
---

# Kiro Crew (Prototype A) — Kubernetes Workspace

A Kubernetes-based Coder template that runs the **Kiro Crew gateway** and its
**web dashboard** inside a single Coder workspace. Kiro CLI is pre-installed, the
dashboard is exposed through Coder's authenticated Workspace Proxy with a
self-authenticating app tile, and the pod is right-sized with per-workspace CPU,
memory, and persistent storage parameters.

> This template is **self-contained** and requires no external Coder auth
> configuration. AWS credentials (when needed) come from the pod's IAM role
> (IRSA) or a manual `aws configure`.

## What is Kiro Crew?

[Kiro Crew](https://github.com/kirodotdev/KiroCrew) is an open-source, persistent
development workspace built on `kiro-cli`. It runs a long-lived **gateway** that
owns memory, transcripts, and artifacts, and exposes a **web dashboard** for
chatting with agents, running multi-step tasks unattended, scheduling recurring
jobs, and extending behavior with skills and MCP servers. In this template the
gateway runs as a Coder `coder_script` and the dashboard is served over Coder's
proxy — so you get Kiro Crew inside your own governed infrastructure, reachable
behind Coder's authentication with no extra ingress to manage.

## Key capabilities

- **Kiro Crew gateway in-workspace** — installed and launched on start as a
  detached process (`coder_script` → `modules/kirocrew/run.sh`); readiness is
  surfaced by the app healthcheck rather than blocking workspace login.
- **Dashboard via Coder Workspace Proxy** — a subdomain `coder_app` ("KiroCrew")
  fronted by a loopback **token-minting redirector**, so clicking the tile lands
  you on an already-authenticated dashboard (no manual `kirocrew token`).
- **Kiro CLI pre-installed** — plus a dedicated **"Kiro CLI"** app for
  interactive authentication (see below).
- **Headless or interactive Kiro auth** — `KIRO_API_KEY` via a per-user Coder
  secret for non-interactive auth, or device-code / Builder ID / SSO sign-in
  through the Kiro CLI app.
- **Coder MCP server wired in** — `~/.kiro/settings/mcp.json` is configured so
  the agent can drive Coder itself (list templates/workspaces, create workspace
  builds, run workspace commands, etc.).
- **Right-sizing + live metrics** — CPU / memory / disk parameters applied as
  Kubernetes limits, with `coder stat` CPU/RAM/disk shown on the workspace page.
- **Persistent home** — a PVC mounted at `/home/coder` keeps installs, Kiro
  credentials, and Kiro Crew state across restarts.
- **Developer tooling** — `code-server` (VS Code in the browser), the Coder Kiro
  app, `git-clone` of a configurable repo, and AWS CLI/CDK from the startup
  script.

## Architecture

```
                 Coder control plane / Workspace Proxy
                                  │  (authenticated ingress)
      ┌───────────────────────────┴────────────────────────────┐
      │  Coder workspace (Kubernetes Deployment + PVC)          │
      │                                                         │
      │   kiro-cli ──┐                                          │
      │              ├─► kirocrew gateway  ──► dashboard :8899  │
      │   MCP (coder)┘        │                                 │
      │                       └─ loopback redirector :8898 ─────┼──► "KiroCrew" app tile
      │   code-server, Kiro app, git-clone, AWS CLI/CDK         │      (self-authenticates)
      │   /home/coder  ◄── ReadWriteOnce PVC (persists)         │
      └─────────────────────────────────────────────────────────┘
```

## Prerequisites

### Infrastructure

- **Kubernetes cluster** with Coder deployed; workspaces are created in the
  `coder` namespace (override with the `namespace` template variable) using the
  `coder` service account.
- **Wildcard DNS / subdomain apps enabled.** The dashboard is a **subdomain**
  `coder_app` (`slug--workspace--owner.<access-host>`). Your Coder deployment
  must serve wildcard app subdomains, or the dashboard tile will not resolve.
- **Container image**: [`codercom/enterprise-base:ubuntu`](https://github.com/coder/enterprise-images/tree/main/images/base).

### Kiro account / model access

- To use **headless** `KIRO_API_KEY` auth you need a Kiro subscription that can
  generate API keys (Pro / Pro+ / Pro Max / Power). On enterprise-managed
  accounts, an administrator must enable API-key generation.
- Otherwise, use **interactive** sign-in (AWS Builder ID or IAM Identity Center)
  through the Kiro CLI app.

## Authenticate to Kiro **first**, then open the dashboard

The gateway starts as soon as the workspace starts, but the agent cannot make
model calls until **Kiro CLI is authenticated**. Do this before you rely on the
dashboard. Kiro credentials resolve from `$HOME` (which is PVC-backed here), so
once you authenticate they persist across restarts.

### Option A — Headless with a Coder secret (recommended)

Create a **per-user Coder secret** that targets the `KIRO_API_KEY` environment
variable **before creating/starting the workspace** (secrets are injected into
the agent environment at start):

```bash
# CLI: paste your Kiro API key when prompted, or pipe it in
printf %s "$YOUR_KIRO_API_KEY" | coder secret create kiro-api-key \
  --description "Kiro CLI headless auth" --env KIRO_API_KEY
```

You can also create the secret from the Coder dashboard (**Account → Secrets**).
On start, `run.sh` detects `KIRO_API_KEY` and `kiro-cli` authenticates
non-interactively — the startup log prints
`✓ Headless Kiro auth: KIRO_API_KEY detected`.

Notes:

- The key is stored in Coder and never written into Terraform state or a
  `coder_parameter`. Enable coderd database encryption to protect it at rest.
- Rotating/deleting the Coder secret does **not** revoke the Kiro key — rotate it
  in the Kiro portal. Either change takes effect on the next workspace start.

### Option B — Interactive sign-in via the Kiro CLI app

If no `KIRO_API_KEY` is set, `run.sh` logs a hint and falls back to interactive
auth:

1. Open the **"Kiro CLI"** app on the workspace page (it runs `kiro-cli` in a
   terminal).
2. Start the guided sign-in (follow the on-screen **device-code** prompt; e.g.
   `kiro-cli login`) and complete authentication in your browser using **AWS
   Builder ID** or **IAM Identity Center**.
3. Verify you are signed in, e.g. `kiro-cli whoami`.

Because the gateway and `kiro-cli` share `$HOME`, sessions started after you
sign in will authenticate automatically.

### Then open the Kiro Crew dashboard

1. Open the **"KiroCrew"** app tile. The loopback redirector mints a short-lived
   token and 302-redirects you to the dashboard, already authenticated.
2. Wait for the app healthcheck to go green (the gateway launches detached and
   can take a moment on cold start). Logs are at `/tmp/kirocrew-gateway.log`.
3. Start a chat/session. If model calls fail with an auth error, complete
   Option A or B above and retry.

## Parameters

| Parameter          | Description                                   | Default | Range          |
|--------------------|-----------------------------------------------|---------|----------------|
| `CPU cores`        | CPU limit for the workspace pod               | `2`     | 2–8            |
| `Memory (__ GB)`   | Memory limit (GiB) for the workspace pod      | `4`     | 4–16           |
| `PVC storage size` | Persistent `/home/coder` storage (GiB)        | `30`    | 10–50 (slider) |
| `git_repo`         | Repository cloned into the workspace on start | `aws-rag-prototyping` | any Git URL |

Template variable `namespace` (default `coder`) selects the Kubernetes namespace.

## Apps

| App          | Purpose                                                            |
|--------------|--------------------------------------------------------------------|
| **KiroCrew** | Kiro Crew web dashboard (subdomain app; self-authenticating tile). |
| **Kiro CLI** | Terminal running `kiro-cli` for interactive Kiro authentication.   |
| **Kiro**     | Coder Kiro registry app.                                           |
| code-server  | VS Code in the browser rooted at `/home/coder`.                    |

## How the dashboard proxy trust works

Kiro Crew's gateway only trusts loopback hosts by default, so a request arriving
through Coder's reverse proxy (a non-loopback `Host`) is rejected with
`"Host header not allowed."` The module fixes this automatically by:

- computing the dashboard's external subdomain origin,
- exporting it as `KIROCREW_CORS_ORIGINS` and running
  `kirocrew config set dashboard.url <origin>` at gateway start, and
- serving the SPA through a **hidden** dashboard `coder_app` while the visible
  tile points at the token-minting redirector.

## Operational notes

- **Gateway launch is detached** (`setsid nohup`) so the Coder agent's SIGTERM of
  long-running start scripts cannot kill it; readiness is reported via the app
  healthcheck (`/health` / `/healthz`).
- **User namespaces / sandbox:** Kiro Crew isolates agent subprocesses with a
  Linux user namespace. Many Kubernetes pods disable this
  (`user.max_user_namespaces=0`); when unavailable the launcher sets
  `agent.sandbox_allow_unsandboxed_exec true` and treats the pod as the isolation
  boundary.
- **Python environment:** the startup script `unset PYTHONPATH PYTHONHOME` before
  installing so Kiro Crew's `~/.kiro/crew-venv` builds cleanly.
- **Persistence:** installs, Kiro credentials, and Kiro Crew state live under the
  PVC-backed `/home/coder` and survive stop/start.
- **Cost/metrics:** `coder stat` CPU/RAM/disk metadata is shown on the workspace
  page; estimated daily cost is set on the pod metadata.

## Further reading

- [Kiro Crew project](https://github.com/kirodotdev/KiroCrew) — upstream docs for
  the gateway, dashboard, skills, and MCP servers.

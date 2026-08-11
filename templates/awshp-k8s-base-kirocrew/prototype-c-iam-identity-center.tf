###############################################################################
# PROTOTYPE C — KiroCrew + AWS IAM Identity Center SSO (enterprise)
#
# For organisations that run their own AWS IAM Identity Center instance.
# Coder acts as the OAuth client; users click "Connect AWS SSO" when creating
# a workspace, Coder stores the token, and the kirocrew module injects it.
#
# Additionally configures the Coder MCP server and passes the SSO token so
# the in-workspace Coder CLI is also authenticated against the same identity.
#
# Prerequisite: configure the Coder server with CODER_EXTERNAL_AUTH_0_*
# variables pointing to your IAM Identity Center OIDC endpoints.
# See external-auth.md for the required server-side configuration (Option B).
###############################################################################

# ── External auth: AWS IAM Identity Center ───────────────────────────────────

data "coder_external_auth" "aws_sso" {
  id = "aws-sso"
}

# ── KiroCrew module with SSO token ───────────────────────────────────────────

module "kirocrew_sso" {
  source   = "./modules/kirocrew"
  agent_id = coder_agent.dev.id

  port  = 8899
  order = 3

  # Inject the SSO token for non-interactive Kiro/KiroCrew authentication
  aws_builder_id_token = data.coder_external_auth.aws_sso.access_token

  # Inject the Coder MCP server alongside the SSO token so KiroCrew can
  # talk to Coder's workspace management API from day one
  extra_mcp_json = jsonencode({
    mcpServers = {
      coder = {
        url     = "${data.coder_workspace.me.access_url}/api/experimental/mcp/http"
        headers = {
          Authorization = "Bearer ${coder_agent.dev.token}"
        }
        autoApprove = [
          "coder_workspace_read_file",
          "coder_workspace_write_file",
          "coder_workspace_bash",
          "coder_workspace_ls",
          "coder_list_workspaces",
          "coder_get_authenticated_user"
        ]
      }
    }
  })
}

# ── IRSA / Pod IAM role annotation (optional) ────────────────────────────────
# If the workspace pod runs under a Kubernetes ServiceAccount that has an
# IAM role via IRSA, the AWS SSO token from external-auth can be *combined*
# with pod-level AWS credentials for a fully authenticated experience.
#
# To enable, set the service_account_name to a SA that has an IAM role
# annotation, e.g.:
#
#   service_account_name = "coder-workspace-sa"
#
# and ensure the SA has this annotation:
#
#   eks.amazonaws.com/role-arn: arn:aws:iam::<ACCOUNT>:role/<ROLE_NAME>
#
# The template already sets service_account_name = "coder" in the
# kubernetes_deployment; change that to a purpose-built SA with IRSA
# when needed.

# ── Startup script addition ───────────────────────────────────────────────────
# Add this block inside the coder_agent startup_script after the existing
# Kiro CLI installation section:
#
#   # Authenticate Kiro CLI with the SSO token provided by Coder external-auth
#   TOKEN=$(coder external-auth access-token aws-sso 2>/dev/null || true)
#   if [ -n "$TOKEN" ]; then
#     kiro-cli auth login --token "$TOKEN" --non-interactive || true
#     echo "Kiro CLI authenticated via AWS SSO"
#   else
#     echo "No AWS SSO token available – run 'coder external-auth' or authenticate manually"
#   fi
#
#   # Refresh the token before the session expires (optional cron approach)
#   # (coder external-auth automatically refreshes via the stored refresh token)

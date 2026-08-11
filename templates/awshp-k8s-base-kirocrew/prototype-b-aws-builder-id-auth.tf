###############################################################################
# PROTOTYPE B — KiroCrew + AWS Builder ID external auth
#
# Extends Prototype A by adding a Coder external-auth data source for
# AWS Builder ID.  The token flows through the kirocrew module variable
# and is injected as an environment variable before the gateway starts,
# enabling non-interactive Kiro authentication.
#
# Prerequisite: configure the Coder server with AWS Builder ID OIDC
# credentials as documented in external-auth.md (Option A).
#
# This file shows only the DIFF relative to prototype-a.  In practice you
# would merge these blocks into a single main.tf.
###############################################################################

# ── External auth: AWS Builder ID ────────────────────────────────────────────
# Requires the Coder server to have CODER_EXTERNAL_AUTH_0_* variables set.
# See external-auth.md for the required server-side configuration.

data "coder_external_auth" "aws_builder_id" {
  # Must match CODER_EXTERNAL_AUTH_0_ID on the server
  id = "aws-builder-id"
}

# ── KiroCrew module with Builder ID token ─────────────────────────────────────
# Replace the module block in prototype-a with this one.

module "kirocrew_with_auth" {
  source   = "./modules/kirocrew"
  agent_id = coder_agent.dev.id   # reference to agent declared in your main.tf
  port     = 8899
  order    = 3

  # Pass the OAuth access token so the gateway can authenticate without
  # an interactive browser flow.
  aws_builder_id_token = data.coder_external_auth.aws_builder_id.access_token
}

# ── Startup script addition ───────────────────────────────────────────────────
# In the coder_agent startup_script, add this after the existing Kiro CLI install:
#
#   TOKEN=$(coder external-auth access-token aws-builder-id 2>/dev/null || true)
#   if [ -n "$TOKEN" ]; then
#     kiro-cli auth login --token "$TOKEN" --non-interactive || true
#     echo "Kiro CLI authenticated via AWS Builder ID"
#   fi

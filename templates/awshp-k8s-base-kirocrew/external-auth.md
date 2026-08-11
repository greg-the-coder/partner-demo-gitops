# AWS Builder ID / IAM Identity Center External Auth for Coder

This file documents how to wire up AWS Builder ID (or an IAM Identity Center
instance) as a Coder external-auth provider so templates can get an access
token on behalf of each workspace user.

## Background

AWS Builder ID and AWS IAM Identity Center both expose an OAuth 2.0 /
OIDC authorization-code flow. Coder's external-auth system can act as the
OAuth client, surfacing a "Connect AWS" button in the workspace creation
wizard and storing the resulting token for use in startup scripts.

### Key endpoints

**AWS Builder ID** (consumer identity, used by Amazon Q, CodeCatalyst, etc.)

| Endpoint | URL |
|---|---|
| Authorization | `https://identitycenter.amazonaws.com/ssooidc/authorize` |
| Token | `https://identitycenter.amazonaws.com/ssooidc/token` |
| JWKS / discovery | `https://identitycenter.amazonaws.com/.well-known/openid-configuration` |

**AWS IAM Identity Center** (SSO for enterprise AWS accounts)

Endpoints are per-region and per-instance, e.g. for `us-east-1`:

| Endpoint | URL |
|---|---|
| Authorization | `https://oidc.us-east-1.amazonaws.com/authorize` |
| Token | `https://oidc.us-east-1.amazonaws.com/token` |

> **Note**: AWS Builder ID / Identity Center primarily supports the
> **Device Authorization Grant** for native apps and CLI tools. The standard
> **Authorization Code + PKCE** flow required by a web server (Coder) is
> available for registered applications — you must register an OAuth
> application in the IAM Identity Center console and obtain a `client_id`
> and `client_secret` (or configure a public client with PKCE only).

## Option A — AWS Builder ID (personal identity)

### 1. Register an OAuth application

Until AWS exposes a self-service portal for Builder ID OAuth apps (currently
in limited preview), this path requires working with the Kiro / AWS team to
get a `client_id` registered.

Once you have credentials, set these environment variables on the **Coder
server**:

```bash
CODER_EXTERNAL_AUTH_0_ID="aws-builder-id"
CODER_EXTERNAL_AUTH_0_TYPE="oidc"   # Coder generic OIDC type
CODER_EXTERNAL_AUTH_0_DISPLAY_NAME="AWS Builder ID"
CODER_EXTERNAL_AUTH_0_DISPLAY_ICON="https://aws.amazon.com/favicon.ico"
CODER_EXTERNAL_AUTH_0_CLIENT_ID="<your-client-id>"
CODER_EXTERNAL_AUTH_0_CLIENT_SECRET="<your-client-secret>"
CODER_EXTERNAL_AUTH_0_AUTH_URL="https://identitycenter.amazonaws.com/ssooidc/authorize"
CODER_EXTERNAL_AUTH_0_TOKEN_URL="https://identitycenter.amazonaws.com/ssooidc/token"
CODER_EXTERNAL_AUTH_0_VALIDATE_URL="https://identitycenter.amazonaws.com/ssooidc/userInfo"
CODER_EXTERNAL_AUTH_0_SCOPES="openid profile sso:account:access"
CODER_EXTERNAL_AUTH_0_PKCE_METHODS="S256"
```

### 2. Add to your Coder template

```hcl
data "coder_external_auth" "aws_builder_id" {
  id = "aws-builder-id"
}
```

The token is then available at:
`data.coder_external_auth.aws_builder_id.access_token`

---

## Option B — AWS IAM Identity Center (enterprise SSO)

For organisations that run their own IAM Identity Center instance.

### 1. Create a custom OIDC application in IAM Identity Center

In the IAM Identity Center console:
1. Go to **Applications → Add application → I have an application I want to set up**
2. Choose **OAuth 2.0**
3. Set the callback URL: `https://<coder-url>/external-auth/aws-sso/callback`
4. Grant the scopes you need: `openid profile email sso:account:access`
5. Note the **Client ID** and **Client Secret**

### 2. Configure the Coder server

```bash
CODER_EXTERNAL_AUTH_0_ID="aws-sso"
CODER_EXTERNAL_AUTH_0_TYPE="oidc"
CODER_EXTERNAL_AUTH_0_DISPLAY_NAME="AWS SSO"
CODER_EXTERNAL_AUTH_0_DISPLAY_ICON="https://aws.amazon.com/favicon.ico"
CODER_EXTERNAL_AUTH_0_CLIENT_ID="<your-client-id>"
CODER_EXTERNAL_AUTH_0_CLIENT_SECRET="<your-client-secret>"
# Replace <REGION> and <INSTANCE-ID> with your IAM Identity Center values
CODER_EXTERNAL_AUTH_0_AUTH_URL="https://oidc.<REGION>.amazonaws.com/authorize"
CODER_EXTERNAL_AUTH_0_TOKEN_URL="https://oidc.<REGION>.amazonaws.com/token"
CODER_EXTERNAL_AUTH_0_VALIDATE_URL="https://oidc.<REGION>.amazonaws.com/userInfo"
CODER_EXTERNAL_AUTH_0_SCOPES="openid profile email sso:account:access"
CODER_EXTERNAL_AUTH_0_PKCE_METHODS="S256"
```

### 3. Add to your Coder template

```hcl
data "coder_external_auth" "aws_sso" {
  id = "aws-sso"
}
```

---

## Using the token inside a workspace

The Coder agent init script can retrieve the current token at any time:

```bash
TOKEN=$(coder external-auth access-token aws-builder-id)
# or
TOKEN=$(coder external-auth access-token aws-sso)
```

Pass it to kiro-cli for non-interactive authentication:

```bash
kiro-cli auth login --token "$TOKEN"
```

Or set it as an environment variable for the KiroCrew gateway:

```bash
export KIRO_AWS_BUILDER_ID_TOKEN="$TOKEN"
kirocrew gateway --port 8899 &
```

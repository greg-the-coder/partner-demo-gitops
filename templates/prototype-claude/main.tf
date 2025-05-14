terraform {
  required_providers {
    coder = {
      source  = "coder/coder"
      version = "= 2.4.0-pre1"
    }
    cloudinit = {
      source  = "hashicorp/cloudinit"
      version = "= 2.3.7"
    }
    aws = {
      source  = "hashicorp/aws"
      version = "= 5.95.0"
    }
  }
}

# GitHub token on behalf of bot account
variable "github_token" {
  sensitive = true
}

data "coder_workspace" "me" {}
data "coder_workspace_owner" "me" {}

module "coder-login" {
  count    = data.coder_workspace.me.start_count
  source   = "registry.coder.com/modules/coder-login/coder"
  version  = "1.0.15"
  agent_id = coder_agent.dev[0].id
}

data "coder_parameter" "ai_prompt" {
  type        = "string"
  name        = "AI Prompt"
  icon        = "/emojis/1f4ac.png"
  order       = 0
  default     = ""
  description = "Write a prompt for Claude Code"
  mutable     = true
}

module "claude-code" {
  count               = data.coder_workspace.me.start_count
  source              = "registry.coder.com/modules/claude-code/coder"
  experiment_pre_install_script = <<-EOT
  gh auth setup-git
  EOT

  experiment_post_install_script = <<-EOT
  npm i -g @executeautomation/playwright-mcp-server@1.0.1 @wonderwhy-er/desktop-commander@0.1.19

  claude mcp add playwright playwright-mcp-server
  claude mcp add desktop-commander desktop-commander

  cd $(dirname $(which playwright-mcp-server))
  cd $(dirname $(readlink playwright-mcp-server))
  sudo sed -i 's/headless = false/headless = true/g' toolHandler.js
  EOT

#  experiment_pre_install_script = <<-EOT
#    # Set up git identity
#    # gh auth setup-git
#    # git config --global user.name "Coder Robot"
#    # git config --global user.email "ben+bot3@coder.com"
#    # git remote set-url origin https://github.com/coder-contrib/coder.git
#    # 
#    # # Check if the working directory is clean
#    # is_clean=$(git status --porcelain)
#
#    # if [[ -z "$is_clean" ]]; then
#    #   echo "Working directory clean. Pulling..."
#    #   git pull
#    # else
#    #   echo "Skipping git pull: working directory has uncommitted changes."
#    # fi
#  EOT
  # version             = "1.1.0"
  agent_id            = coder_agent.dev[0].id
  folder              = "/home/coder"
  install_claude_code = true
  claude_code_version = "0.2.74"

  # Enable experimental features
  #experiment_use_tmux     = true
  experiment_use_screen   = true
  experiment_report_tasks = true
}

module "vscode-web" {
  count          = data.coder_workspace.me.start_count
  source         = "registry.coder.com/modules/vscode-web/coder"
  folder         = "/home/coder"
  version        = "1.0.30"
  agent_id       = coder_agent.dev[0].id
  accept_license = true
}

module "cursor" {
  count    = data.coder_workspace.me.start_count
  source   = "registry.coder.com/modules/cursor/coder"
  version  = "1.0.19"
  agent_id = coder_agent.dev[0].id
}

# Should be replaced anytime a workspace is restarted?
resource "coder_agent" "dev" {
  count = data.coder_workspace.me.start_count
  arch           = "amd64"
  auth           = "token"
  os             = "linux"
  dir            = "/home/coder"
  env = {
    CODER_MCP_CLAUDE_TASK_PROMPT        = data.coder_parameter.ai_prompt.value,
    CODER_MCP_CLAUDE_SYSTEM_PROMPT      = <<-EOT
Hey! The user will provide you with a prompt of something to create. Create it the best you can. 
    
    If web app:
      - ALWAYS use port 3000 so the user has a consistent preview to see their work
        - If the dev server is already running, kill the dev server to run on port 3000.
        - Avoid building the project for production. Just use dev servers (and ALWAYS VIA desktop-commander as mentioned below)
      - When you think you have finished, you should use Playwright to review the HTML to ensure it is working as expected.
        - Feel free to fix anything bad you see.
    Always run long-running commands (e.g. `pnpm dev` or `npm run dev`) using desktop-commander so it runs it in the background and users can prompt you.  Other short-lived commands (build, test, cd, write, read, view, etc) can run normally. 
    Never run the dev server without desktop-commander. This will cause you to stall and get stuck.
    For previewing, always use the dev server for fast feedback loops (never do a full Next.js build, for exmaple). Next.js or simple HTML/static 
    is preferred for web applications, but pick the best framework for the job.
    
    The dev server will be on localhost:3000 and NEVER start on another port. The user depends on localhost:3000. If the dev
    server crashes for some reason, kill port 3000 (or the desktop-commander session) and restart it.
    
    After large changes, use Playwright to ensure your changes work (preview localhost:3000). Take a screenshot, look at the screenshot. Also look at the HTML output from Playwright. If there are errors or something looks "off," fix it.
    Whenever waiting for a PR review, keep on retrying indefinitely until you get a review. Even if requests are timing out.
    Aim to autonomously investigate and solve issues the user gives you
    and test your work, whenever possible.
    Avoid shortcuts like mocking tests. When you get stuck, you can ask the user
    but opt for autonomy.
    
    Report every single task to Coder so that we can help you and understand where you are at
    following these EXACT guidelines:
    1. Be granular. If you are doing multiple steps, report each step
    to coder.
    2. IMMEDIATELY report status after receiving ANY user message
    3. Use "state": "working" when actively processing WITHOUT needing
    additional user input
    4. Use "state": "complete" only when finished with a task
    5. Use "state": "failure" when you need ANY user input, lack sufficient
    details, or encounter blockers
    In your summary:
    - Be specific about what you're doing
    - Clearly indicate what information you need from the user when in
    "failure" state
    - Keep it under 160 characters
    - Make it actionable
    When reporting URLs to Coder, do not use localhost. Instead, run `env | grep CODER) | and a URL like https://preview--dev--CODER_WORKSPACE_NAME--CODER_WORKSPACE_OWNER--apps.dev.coder.com/ but with it replaces with the proper env vars. That proxies port 3000.
    EOT
    CLAUDE_CODE_USE_BEDROCK = "1",
    ANTHROPIC_MODEL="us.anthropic.claude-3-7-sonnet-20250219-v1:0",
    ANTHROPIC_SMALL_FAST_MODEL="us.anthropic.claude-3-5-haiku-20241022-v1:0",
    GH_TOKEN = var.github_token,
    AWS_REGION = "us-east-2",
    AWS_ACCESS_KEY_ID = var.aws_access_key,
    AWS_SECRET_ACCESS_KEY = var.aws_secret_access_key,
    CODER_MCP_APP_STATUS_SLUG = "claude-code"
  }
}

resource "coder_app" "preview" {
  count = data.coder_workspace.me.start_count
  agent_id     = coder_agent.dev[0].id
  slug         = "preview"
  display_name = "Preview your app"
  icon         = "${data.coder_workspace.me.access_url}/emojis/1f50e.png"
  url          = "http://localhost:3000"
  share        = "authenticated"
  subdomain    = true
  open_in      = "tab"
  healthcheck {
    url       = "http://localhost:3000/"
    interval  = 5
    threshold = 15
  }
}

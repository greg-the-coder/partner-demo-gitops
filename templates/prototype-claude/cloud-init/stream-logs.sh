#!/usr/bin/env bash
# Change to only show executed commands and treat unset variables as errors
set -ux

# --- Default configurable options ---
LOG_FILE="${LOG_FILE:-/tmp/cloud-init.coder.log}"
STREAMER_LOG="${STREAMER_LOG:-/tmp/streamer.log}"
MODE="${MODE:-foreground}"  # Default to foreground, but allow env var override
PID_FILE="${PID_FILE:-/tmp/coder-log-streamer.pid}"
VERBOSE="${VERBOSE:-false}"

# Create streamer log file with proper permissions if needed
sudo touch "$STREAMER_LOG"
sudo chmod 666 "$STREAMER_LOG"

# --- Parse args (these override env vars) ---
for arg in "$@"; do
  case "$arg" in
    --background)
      MODE="background"
      ;;
    --foreground)
      MODE="foreground"
      ;;
    --log-file=*)
      LOG_FILE="${arg#*=}"
      ;;
    --streamer-log=*)
      STREAMER_LOG="${arg#*=}"
      ;;
    --pid-file=*)
      PID_FILE="${arg#*=}"
      ;;
    --verbose)
      VERBOSE="true"
      ;;
    --help)
      echo "Usage: $0 [options]"
      echo "Options:"
      echo "  --background           Run in background mode"
      echo "  --foreground           Run in foreground mode (default)"
      echo "  --log-file=FILE        Specify the log file to watch (default: $LOG_FILE)"
      echo "  --streamer-log=FILE    Specify the streamer log file (default: $STREAMER_LOG)"
      echo "  --pid-file=FILE        Specify the PID file location (default: $PID_FILE)"
      echo "  --verbose              Enable verbose output"
      echo "  --help                 Show this help message"
      echo ""
      echo "Environment variables:"
      echo "  LOG_FILE               Same as --log-file"
      echo "  STREAMER_LOG           Same as --streamer-log"
      echo "  MODE                   Set to 'background' or 'foreground'"
      echo "  PID_FILE               Same as --pid-file"
      echo "  VERBOSE                Set to 'true' for verbose output"
      echo "  CODER_AGENT_TOKEN      Required: Coder agent token"
      echo "  CODER_AGENT_URL        Required: Coder agent URL"
      echo "  LOG_SOURCE_NAME        Optional: Name for the log source (default: cloud_init)"
      echo "  LOG_SOURCE_ICON        Optional: Icon URL for the log source"
      exit 0
      ;;
    *)
      echo "Unknown argument: $arg"
      echo "Use --help to see available options"
      exit 1
      ;;
  esac
done

# Helper function for logging
log() {
  local message="$1"
  local timestamp=$(date -Iseconds)
  echo "[$timestamp] $message" >> "$STREAMER_LOG"
  if [ "$VERBOSE" = "true" ]; then
    echo "[$timestamp] $message"
  fi
}

# --- Required env vars ---
CODER_AGENT_TOKEN="${CODER_AGENT_TOKEN:?Missing CODER_AGENT_TOKEN}"
CODER_AGENT_URL="${CODER_AGENT_URL:?Missing CODER_AGENT_URL}"
LOG_SOURCE_NAME="${LOG_SOURCE_NAME:-cloud_init}"
LOG_SOURCE_ICON="${LOG_SOURCE_ICON:-https://cloud-init.github.io/images/cloud-init-orange.svg}"

log "Using log file: $LOG_FILE"
log "Coder agent URL: $CODER_AGENT_URL"
log "Running in $MODE mode"

# --- Generate UUID ---
LOG_SOURCE_ID=$(cat /proc/sys/kernel/random/uuid)
log "UUID generated: $LOG_SOURCE_ID"

# --- Register the log source with Coder ---
log "Registering log source..."
register_payload=$(cat <<EOF
{
  "display_name": "$LOG_SOURCE_NAME",
  "icon": "$LOG_SOURCE_ICON",
  "id": "$LOG_SOURCE_ID"
}
EOF
)

# Register the log source
log "Making registration request..."
register_code=$(curl -s -X POST "$CODER_AGENT_URL/api/v2/workspaceagents/me/log-source" \
  -H "Content-Type: application/json" \
  -H "Accept: application/json" \
  -H "Coder-Session-Token: $CODER_AGENT_TOKEN" \
  -d "$register_payload" -w "%{http_code}" -o /dev/null)

log "Registration response code: $register_code"

if [ "$register_code" != "201" ] && [ "$register_code" != "200" ]; then
  log "Failed to register log source. HTTP $register_code"
  exit 1
fi

log "Log source registered with ID: $LOG_SOURCE_ID"

# --- Ensure log file exists and is world-writable ---
sudo touch "$LOG_FILE"
sudo chmod 666 "$LOG_FILE"
echo "Log streamer started at $(date)" > "$LOG_FILE"

# --- Logging function ---
stream_logs() {
  log "Watching $LOG_FILE for log lines..."
  
  # Use tail to follow the log file
  tail -n0 -F "$LOG_FILE" 2>> "$STREAMER_LOG" | while read -r line; do
    if [ "$VERBOSE" = "true" ]; then
      log "Read line: $line"
    fi
    [ -z "$line" ] && continue
    
    ts=$(date -Iseconds)
    
    # Properly escape the line for JSON
    escaped_line=$(echo "$line" | sed 's/"/\\"/g' | sed 's/\\/\\\\/g')
    
    if [ "$VERBOSE" = "true" ]; then
      log "Sending log line to Coder..."
    fi
    
    # Use the correct API endpoint with PATCH method
    curl_response=$(curl -s -X PATCH "$CODER_AGENT_URL/api/v2/workspaceagents/me/logs" \
      -H "Content-Type: application/json" \
      -H "Accept: application/json" \
      -H "Coder-Session-Token: $CODER_AGENT_TOKEN" \
      -d "{
        \"log_source_id\": \"$LOG_SOURCE_ID\",
        \"logs\": [
          {
            \"created_at\": \"$ts\",
            \"level\": \"info\",
            \"output\": \"$escaped_line\"
          }
        ]
      }" -w "%{http_code}" -o /dev/null)
    
    if [ "$VERBOSE" = "true" ] || [ "$curl_response" != "200" ]; then
      log "Sent line, got status: $curl_response"
    fi
  done
  
  log "Exited the tail loop"
}

# --- Start in chosen mode ---
log "Starting log streamer in $MODE mode..."
if [ "$MODE" = "background" ]; then
  # Start in background
  (stream_logs &)
  echo $! > "$PID_FILE"
  disown
  log "PID stored in $PID_FILE"
else
  # Start in foreground
  stream_logs
fi

log "Script execution complete"
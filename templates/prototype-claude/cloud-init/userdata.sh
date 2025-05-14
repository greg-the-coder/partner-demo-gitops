#!/usr/bin/env bash
set -eux

# Ensure ubuntu group exists
if ! getent group ubuntu >/dev/null; then
  groupadd ubuntu
fi

# Setup AWS credentials
mkdir -p /home/ubuntu/.aws
cat <<EOF > /home/ubuntu/.aws/credentials
[default]
credential_source=Ec2InstanceMetadata
region=${region}
EOF

chown -R ubuntu:ubuntu /home/ubuntu/.aws
chmod 600 /home/ubuntu/.aws/credentials

# Fetch token to communicate with this AWS instance
TOKEN=$(curl -s -X PUT "http://169.254.169.254/latest/api/token" -H "X-aws-ec2-metadata-token-ttl-seconds: 300")

# Fetch Coder Agent Token
export CODER_AGENT_TOKEN=$(curl -s -H "X-aws-ec2-metadata-token: $TOKEN" \
  http://169.254.169.254/latest/meta-data/tags/instance/Coder_Agent_Token)

# Fetch Coder Agent URL
export CODER_AGENT_URL=$(curl -s -H "X-aws-ec2-metadata-token: $TOKEN" \
  http://169.254.169.254/latest/meta-data/tags/instance/Coder_Agent_URL)

LOG_SOURCE_NAME='cloud_init' \
MODE=background \
/usr/local/bin/stream-logs.sh &


if [ "${debug_mode}" = "true" ]; then
#   For troubleshooting the root environment
  sudo -u 'ubuntu' env CODER_AGENT_TOKEN="$CODER_AGENT_TOKEN" sh -c '${init_script}' &
else
  sudo -u 'ubuntu' env CODER_AGENT_TOKEN="$CODER_AGENT_TOKEN" init_script='${init_script}' bash -c '
  set -eux

  LOG_FILE=/tmp/cloud-init.coder.log
  sudo touch "$LOG_FILE"
  sudo chmod 666 "$LOG_FILE"
  echo "Starting devcontainer debug run at $(date)" > "$LOG_FILE"

  IMAGE="coder-universal-image"
  CONTAINER_NAME="coder-universal"

  echo "[docker run] Launching container..." >> "$LOG_FILE"
  docker run -dit --name "$CONTAINER_NAME" --hostname "$CONTAINER_NAME" "$IMAGE" >> "$LOG_FILE"

  container_id=$(docker ps -qf "name=$CONTAINER_NAME")
  echo "Container ID: $container_id" >> "$LOG_FILE"

  echo "[docker exec] Running init_script inside container..." >> "$LOG_FILE"
  docker exec "$container_id" env CODER_AGENT_TOKEN=$CODER_AGENT_TOKEN BINARY_DIR="/home/coder/.bin" bash -c "mkdir -p /home/coder/.bin && $init_script"

  echo "Finished Docker container debug run at $(date)" >> "$LOG_FILE"
' &
fi

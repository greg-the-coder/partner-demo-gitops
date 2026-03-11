#!/bin/bash
#Sync the latest commit of the templates to current Coder deployment
#
#Token from Coder Login passed in as a parameter 1
#

#Setup GitOps environment
export TF_VAR_coder_url=$CODER_AGENT_URL
export TF_VAR_coder_token=$1
export TF_VAR_coder_gitsha="$(git log -1 --format=%H)"
 
MAX_ATTEMPTS=5
ATTEMPT=1

while [ $ATTEMPT -le $MAX_ATTEMPTS ]; do
  echo "Terraform attempt $ATTEMPT/$MAX_ATTEMPTS"
  if terraform refresh && terraform apply -auto-approve; then
    echo "Terraform apply successful"
    exit 0
  fi

  if [ $ATTEMPT -lt $MAX_ATTEMPTS ]; then
    WAIT_TIME=$((ATTEMPT * 30))
    echo "Terraform failed, waiting ${WAIT_TIME}s before retry..."
    sleep $WAIT_TIME
  fi

  ATTEMPT=$((ATTEMPT + 1))

done

echo "Terraform apply failed after $MAX_ATTEMPTS attempts"
exit 1
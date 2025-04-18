#Sync the latest commit of the templates to current Coder deployment
#
#Token from Coder Login passed in as a parameter 1
#

#Setup GitOps environment
export TF_VAR_coder_url=$CODER_AGENT_URL
export TF_VAR_coder_token=$1
export TF_VAR_coder_gitsha="$(git log -1 --format=%H)"

#Execute Terraform Sync
terraform refresh
terraform apply
#!/bin/bash

# Set variables
USER_NAME="BedrockAPIKey_$(date +%s)"
CREDENTIAL_AGE_DAYS=90

echo "Creating IAM user: $USER_NAME"

# Step 1: Create IAM user
aws iam create-user --user-name $USER_NAME

# Step 2: Attach Bedrock policy
aws iam attach-user-policy \
    --user-name $USER_NAME \
    --policy-arn arn:aws:iam::aws:policy/AmazonBedrockLimitedAccess

# Step 3: Create Bedrock API key (CORRECTED)
echo "Creating Bedrock API key..."
BEDROCK_KEY_OUTPUT=$(aws iam create-service-specific-credential \
    --user-name $USER_NAME \
    --service-name bedrock.amazonaws.com \
    --credential-age-days $CREDENTIAL_AGE_DAYS)

# Extract the API key from the output
BEDROCK_API_KEY=$(echo $BEDROCK_KEY_OUTPUT | jq -r '.ServiceSpecificCredential.ServicePassword')

# Step 4: Create IAM access keys
echo "Creating IAM access keys..."
ACCESS_KEY_OUTPUT=$(aws iam create-access-key --user-name $USER_NAME)

ACCESS_KEY_ID=$(echo $ACCESS_KEY_OUTPUT | jq -r '.AccessKey.AccessKeyId')
SECRET_ACCESS_KEY=$(echo $ACCESS_KEY_OUTPUT | jq -r '.AccessKey.SecretAccessKey')

# Step 5: Export environment variables
export AWS_BEARER_TOKEN_BEDROCK="$BEDROCK_API_KEY"
export AWS_ACCESS_KEY_ID="$ACCESS_KEY_ID"
export AWS_SECRET_ACCESS_KEY="$SECRET_ACCESS_KEY"
export AWS_DEFAULT_REGION="us-east-1"

echo "Environment variables set:"
echo "AWS_BEARER_TOKEN_BEDROCK: $AWS_BEARER_TOKEN_BEDROCK"
echo "AWS_ACCESS_KEY_ID: $AWS_ACCESS_KEY_ID"
echo "AWS_SECRET_ACCESS_KEY: [HIDDEN]"
echo "AWS_DEFAULT_REGION: $AWS_DEFAULT_REGION"

# Save to file for later use
cat > bedrock_credentials.env << EOF
export AWS_BEARER_TOKEN_BEDROCK="$BEDROCK_API_KEY"
export AWS_ACCESS_KEY_ID="$ACCESS_KEY_ID"
export AWS_SECRET_ACCESS_KEY="$SECRET_ACCESS_KEY"
export AWS_DEFAULT_REGION="us-east-1"
EOF

echo "Credentials saved to bedrock_credentials.env"
echo "To use later: source bedrock_credentials.env"

echo "*** Creating Kubernetes Secrets ***"
aws eks update-kubeconfig --region us-east-1 --name coder-aws-cluster
kubectl delete secret aws-bedrock-config -n coder
kubectl create secret generic aws-bedrock-config -n coder \
--from-literal=region="$AWS_DEFAULT_REGION" \
--from-literal=access-key="$AWS_ACCESS_KEY_ID" \
--from-literal=access-key-secret="$AWS_SECRET_ACCESS_KEY"
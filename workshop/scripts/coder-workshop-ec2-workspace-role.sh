#!/bin/bash

# Script to create IAM role for coder workshop with resource limits
# Role name: coder-workshop-ec2-workspace-role
# Features: Serverless development, Bedrock integration, resource limits
# Restriction: No EC2 instance deployment capability

set -e  # Exit on any error

ROLE_NAME="coder-workshop-ec2-workspace-role"
INSTANCE_PROFILE_NAME="coder-workshop-ec2-workspace-profile"
POLICY_NAME="CoderWorkshopResourceLimitedPolicy"

echo "Creating IAM role: $ROLE_NAME"

# Step 1: Create the IAM role with trust policy for EC2
aws iam create-role \
    --role-name $ROLE_NAME \
    --assume-role-policy-document '{
        "Version": "2012-10-17",
        "Statement": [
            {
                "Effect": "Allow",
                "Principal": {
                    "Service": "ec2.amazonaws.com"
                },
                "Action": "sts:AssumeRole"
            }
        ]
    }' \
    --description "IAM role for coder workshop with serverless development and Bedrock integration, no EC2 deployment"

echo "IAM role created successfully"

# Step 2: Create and attach comprehensive custom policy with resource limits
echo "Creating and attaching custom policy with resource limits"

aws iam put-role-policy \
    --role-name $ROLE_NAME \
    --policy-name $POLICY_NAME \
    --policy-document '{
        "Version": "2012-10-17",
        "Statement": [
            {
                "Sid": "DenyEC2InstanceDeployment",
                "Effect": "Deny",
                "Action": [
                    "ec2:RunInstances",
                    "ec2:StartInstances"
                ],
                "Resource": "*"
            },
            {
                "Sid": "LimitedLambdaAccess",
                "Effect": "Allow",
                "Action": [
                    "lambda:CreateFunction",
                    "lambda:UpdateFunctionCode",
                    "lambda:UpdateFunctionConfiguration",
                    "lambda:InvokeFunction",
                    "lambda:GetFunction",
                    "lambda:ListFunctions",
                    "lambda:DeleteFunction",
                    "lambda:GetFunctionConfiguration",
                    "lambda:CreateEventSourceMapping",
                    "lambda:DeleteEventSourceMapping",
                    "lambda:GetEventSourceMapping",
                    "lambda:ListEventSourceMappings"
                ],
                "Resource": "*",
                "Condition": {
                    "NumericLessThan": {
                        "lambda:FunctionCount": "50"
                    }
                }
            },
            {
                "Sid": "LimitedS3Access",
                "Effect": "Allow",
                "Action": [
                    "s3:CreateBucket",
                    "s3:GetObject",
                    "s3:PutObject",
                    "s3:DeleteObject",
                    "s3:ListBucket",
                    "s3:GetBucketLocation",
                    "s3:GetBucketVersioning",
                    "s3:PutBucketVersioning",
                    "s3:GetBucketPolicy",
                    "s3:PutBucketPolicy"
                ],
                "Resource": "*",
                "Condition": {
                    "NumericLessThan": {
                        "s3:BucketCount": "20"
                    }
                }
            },
            {
                "Sid": "LimitedDynamoDBAccess",
                "Effect": "Allow",
                "Action": [
                    "dynamodb:CreateTable",
                    "dynamodb:DeleteTable",
                    "dynamodb:DescribeTable",
                    "dynamodb:GetItem",
                    "dynamodb:PutItem",
                    "dynamodb:UpdateItem",
                    "dynamodb:DeleteItem",
                    "dynamodb:Query",
                    "dynamodb:Scan",
                    "dynamodb:BatchGetItem",
                    "dynamodb:BatchWriteItem",
                    "dynamodb:ListTables"
                ],
                "Resource": "*",
                "Condition": {
                    "NumericLessThan": {
                        "dynamodb:TableCount": "25"
                    }
                }
            },
            {
                "Sid": "LimitedAPIGatewayAccess",
                "Effect": "Allow",
                "Action": [
                    "apigateway:GET",
                    "apigateway:POST",
                    "apigateway:PUT",
                    "apigateway:DELETE",
                    "apigateway:PATCH"
                ],
                "Resource": "*",
                "Condition": {
                    "NumericLessThan": {
                        "apigateway:ApiCount": "10"
                    }
                }
            },
            {
                "Sid": "BedrockAccess",
                "Effect": "Allow",
                "Action": [
                    "bedrock:InvokeModel",
                    "bedrock:InvokeModelWithResponseStream",
                    "bedrock:ListFoundationModels",
                    "bedrock:GetFoundationModel",
                    "bedrock:CreateKnowledgeBase",
                    "bedrock:GetKnowledgeBase",
                    "bedrock:ListKnowledgeBases",
                    "bedrock:CreateDataSource",
                    "bedrock:GetDataSource",
                    "bedrock:ListDataSources"
                ],
                "Resource": "*"
            },
            {
                "Sid": "CloudWatchLogsAccess",
                "Effect": "Allow",
                "Action": [
                    "logs:CreateLogGroup",
                    "logs:CreateLogStream",
                    "logs:PutLogEvents",
                    "logs:DescribeLogGroups",
                    "logs:DescribeLogStreams"
                ],
                "Resource": "*"
            },
            {
                "Sid": "IAMPassRoleForLambda",
                "Effect": "Allow",
                "Action": "iam:PassRole",
                "Resource": "arn:aws:iam::*:role/lambda-*"
            }
        ]
    }'

echo "Custom policy attached successfully"

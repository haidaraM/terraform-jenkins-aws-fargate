#!/bin/bash

set -e

# Start Containerd and wait a few seconds for it to stabilise
echo Starting Containerd
containerd > /dev/null 2>&1 &
sleep 3

# Test Containerd is working ok
ctr version > /dev/null

echo Pulling Container Image "$1"

# Log into ECR
if [[ "$1" == public* ]]
  then
  echo "Logging into ECR Public"
  # ECR Public only accepts the us-east-1 value for authentication
  PASSWORD=$(aws ecr-public get-login-password --region us-east-1)
else
  echo "Logging into ECR"
  PASSWORD=$(aws ecr get-login-password --region "${AWS_REGION}")
fi

ARCH_VALUE=${IMAGE_ARCH:-"linux/amd64"}
echo "Pulling image for platform: ${ARCH_VALUE}"
ctr image pull \
  --platform="${ARCH_VALUE}" \
  --user="AWS:${PASSWORD}" \
  "$1" > /dev/null

# Create SOCI Index
echo Creating Soci Index
MIN_LAYER_SIZE_VALUE=${MIN_LAYER_SIZE:-10}
soci create --platform="$ARCH_VALUE" --min-layer-size "$MIN_LAYER_SIZE_VALUE" "$1"

echo Pushing Soci Index
soci push --platform="$ARCH_VALUE" --user AWS:"$PASSWORD" "$1"

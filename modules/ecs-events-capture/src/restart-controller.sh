#!/bin/bash
# This script generates a series of ECS service updates to trigger ECS events to have some data to compare.

set -e

# Set your ECS cluster name and service name. This is the default values. Change them if you have different names.
ECS_CLUSTER_NAME="jenkins-cluster"
ECS_SERVICE_NAME="jenkins-controller"

# Number of updates
NUM_UPDATES=10

# AWS CLI command to force update ECS service
update_service() {
    aws ecs update-service --cluster $ECS_CLUSTER_NAME --service $ECS_SERVICE_NAME --force-new-deployment
}

# AWS CLI command to check service stability
check_service_stability() {
    echo "Checking service stability..."
    aws ecs wait services-stable --cluster $ECS_CLUSTER_NAME --services $ECS_SERVICE_NAME
    echo "Service is stable."
}

# Perform updates
for ((i=1; i<=$NUM_UPDATES; i++)); do
    echo "Starting update $i..."
    update_service
    check_service_stability
done


echo "All updates completed."
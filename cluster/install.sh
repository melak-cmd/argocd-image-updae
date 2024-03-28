#!/bin/bash

# Color definitions for output messages
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[0;33m'
NC='\033[0m' # No Color

# Accept cluster_name as argument or set a default value
cluster_name="${1:-argo}"

# Function to wait for deployments in a specified namespace to be ready
wait_for_deployments() {
    local namespace="$1"
    echo -e "${YELLOW}Waiting for deployments in '$namespace' namespace to be ready...${NC}"
    kubectl wait --for=condition=available deployment --all -n "$namespace"
    kubectl wait --for=condition=Ready pod --all -n "$namespace"
    echo -e "${GREEN}Deployments in '$namespace' namespace are ready.${NC}"
}

# Define the command to create a Kubernetes cluster using k3d
command="k3d cluster create $cluster_name --servers 1 --agents 2 --api-port master.127.0.0.1.nip.io:6445 --port '80:80@loadbalancer' \
--port '443:443@loadbalancer' --volume /tmp/k3dvol:/tmp/k3dvol --k3s-arg=\"--disable=traefik@server:*\" --wait"

# Print the command being executed
echo -e "${YELLOW}Executing command: ${command}${NC}"

# Check if the cluster already exists
output=$(k3d cluster list --no-headers | awk '{print $1}')
if echo "$output" | grep -wq "$cluster_name"; then
    echo -e "${RED}Cluster '$cluster_name' already exists.${NC}"
else
    # Create the cluster if it doesn't exist
    if eval "$command"; then
        echo -e "${GREEN}Cluster '$cluster_name' created successfully.${NC}"
    else
        echo -e "${RED}Failed to create the cluster.${NC}"
        exit 0
    fi
fi

# Wait for deployments in the 'kube-system' namespace to be ready
wait_for_deployments "kube-system"
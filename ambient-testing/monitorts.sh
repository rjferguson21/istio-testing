#!/bin/bash

# Colors
GREEN='\033[0;32m'
RED='\033[0;31m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Function to check if a connection is successful from logs
check_connection() {
    local namespace=$1
    local deployment=$2
    local target=$3
    local lines=${4:-20}

    # Get recent logs
    local logs=$(kubectl logs --tail=$lines deployment/$deployment -n $namespace 2>/dev/null)

    if [ -z "$logs" ]; then
        echo "${RED}✗${NC}"
        return
    fi

    # Check for success message for the specific target
    if echo "$logs" | grep -q "Successfully connected to $target"; then
        echo "${GREEN}✓${NC}"
    elif echo "$logs" | grep -q "Failed to connect to $target"; then
        echo "${RED}✗${NC}"
    else
        echo "${YELLOW}?${NC}"
    fi
}

# Function to check pod status
check_pod_status() {
    local namespace=$1
    local deployment=$2

    local status=$(kubectl get deployment $deployment -n $namespace -o jsonpath='{.status.conditions[?(@.type=="Available")].status}' 2>/dev/null)

    if [ "$status" = "True" ]; then
        echo "${GREEN}Running${NC}"
    else
        echo "${RED}Not Ready${NC}"
    fi
}

# Clear screen and show header
clear
echo "$(date)"
echo ""

# Check if cluster is accessible
if ! kubectl cluster-info &>/dev/null; then
    echo "${RED}Error: Cannot connect to Kubernetes cluster${NC}"
    exit 1
fi

# Ambient App (polls 2 targets)
echo -e "${BLUE}ambient-app${NC} (Ambient Mesh Client)"
echo -e "  Pod Status: $(check_pod_status ambient-app ambient-app)"
echo -e "  → sidecar-app-receive:  $(check_connection ambient-app ambient-app sidecar-app-receive)"
echo -e "  → ambient-app-receive:  $(check_connection ambient-app ambient-app ambient-app-receive)"
echo ""

# Sidecar App (polls 2 targets)
echo -e "${BLUE}sidecar-app${NC} (Sidecar Proxy Client)"
echo -e "  Pod Status: $(check_pod_status sidecar-app sidecar-app)"
echo -e "  → ambient-app-receive:  $(check_connection sidecar-app sidecar-app ambient-app-receive)"
echo -e "  → sidecar-app-receive:  $(check_connection sidecar-app sidecar-app sidecar-app-receive)"
echo ""

# Non-mesh App (polls 1 target)
echo -e "${BLUE}non-mesh-app${NC} (Non-Mesh Client)"
echo -e "  Pod Status: $(check_pod_status non-mesh-app non-mesh-app)"
echo -e "  → ambient-app-receive:  $(check_connection non-mesh-app non-mesh-app ambient-app-receive)"
echo ""

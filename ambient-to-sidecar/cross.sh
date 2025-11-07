#!/bin/bash

set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
CLUSTER_SCRIPT="../cluster.sh"

echo "========================================="
echo "Istio Ambient to Sidecar Test Deployment"
echo "========================================="
echo ""

# Step 1: Create cluster
echo "Step 1/3: Creating cluster with Istio..."
echo ""
if [ -f "${SCRIPT_DIR}/${CLUSTER_SCRIPT}" ]; then
    bash "${SCRIPT_DIR}/${CLUSTER_SCRIPT}"
else
    echo "Error: cluster.sh not found at ${SCRIPT_DIR}/${CLUSTER_SCRIPT}"
    exit 1
fi

echo ""
echo "Waiting for Istio components to stabilize..."
sleep 10

# Step 2: Deploy sidecar app first (so it's ready when ambient app starts polling)
echo ""
echo "Step 2/3: Deploying sidecar application..."
echo ""
bash "${SCRIPT_DIR}/sidecar-app.sh"

echo ""
echo "Waiting for sidecar app to be fully ready..."
sleep 5

# Step 3: Deploy ambient app
echo ""
echo "Step 3/3: Deploying ambient application..."
echo ""
bash "${SCRIPT_DIR}/ambient-app.sh"

echo ""
echo "========================================="
echo " Deployment Complete!"
echo "========================================="
echo ""
echo "Summary:"
echo "  - Cluster: istio-cluster (k3d)"
echo "  - Sidecar App: sidecar-app namespace"
echo "  - Ambient App: ambient-app namespace"
echo ""
echo "Next Steps:"
echo ""
echo "1. Check ambient app logs to see connection attempts:"
echo "   kubectl logs -f deployment/ambient-app -n ambient-app"
echo ""
echo "2. Check sidecar app status:"
echo "   kubectl get pods -n sidecar-app"
echo ""
echo "3. Test connectivity manually:"
echo "   kubectl exec -it deployment/ambient-app -n ambient-app -- curl http://sidecar-service.sidecar-app.svc.cluster.local:8080"
echo ""
echo "4. Apply network policies if needed to test minimum requirements"
echo ""

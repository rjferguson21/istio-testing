#!/bin/bash

set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
CLUSTER_SCRIPT="../cluster.sh"

echo "========================================="
echo "Istio Ambient to Sidecar Test Deployment"
echo "========================================="
echo ""

# Step 1: Create cluster
echo "Step 1/5: Creating cluster with Istio..."
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
echo "Step 2/5: Deploying sidecar application..."
echo ""
bash "${SCRIPT_DIR}/sidecar-app.sh"

echo ""
echo "Waiting for sidecar app to be fully ready..."
sleep 5

# Step 3: Deploy ambient-app-receive (so it's ready when ambient app starts polling)
echo ""
echo "Step 3/5: Deploying ambient-app-receive..."
echo ""
bash "${SCRIPT_DIR}/ambient-app-receive.sh"

echo ""
echo "Waiting for ambient-app-receive to be fully ready..."
sleep 5

# Step 4: Deploy non-mesh app (demonstrates direct port 8080 traffic)
echo ""
echo "Step 4/5: Deploying non-mesh application..."
echo ""
bash "${SCRIPT_DIR}/non-mesh-app.sh"

echo ""
echo "Waiting for non-mesh-app to be fully ready..."
sleep 5

# Step 5: Deploy ambient app
echo ""
echo "Step 5/5: Deploying ambient application..."
echo ""
bash "${SCRIPT_DIR}/ambient-app.sh"

echo ""
echo "========================================="
echo " Deployment Complete!"
echo "========================================="
echo ""
echo "Summary:"
echo "  - Cluster: istio-cluster (k3d)"
echo "  - Sidecar App: sidecar-app namespace (sidecar proxy)"
echo "  - Ambient App Receive: ambient-app-receive namespace (ambient mesh)"
echo "  - Non-Mesh App: non-mesh-app namespace (NO mesh, NO sidecar)"
echo "  - Ambient App: ambient-app namespace (ambient mesh)"
echo ""
echo "Next Steps:"
echo ""
echo "1. Check ambient app logs (mesh traffic via HBONE):"
echo "   kubectl logs -f deployment/ambient-app -n ambient-app"
echo ""
echo "2. Check non-mesh app logs (direct traffic on port 8080):"
echo "   kubectl logs -f deployment/non-mesh-app -n non-mesh-app"
echo ""
echo "3. Check network policies on ambient-app-receive:"
echo "   kubectl get networkpolicies -n ambient-app-receive"
echo ""
echo "4. Test connectivity manually:"
echo "   kubectl exec -it deployment/ambient-app -n ambient-app -- curl http://sidecar-service.sidecar-app.svc.cluster.local:8080"
echo "   kubectl exec -it deployment/ambient-app -n ambient-app -- curl http://ambient-service-receive.ambient-app-receive.svc.cluster.local:8080"
echo "   kubectl exec -it deployment/non-mesh-app -n non-mesh-app -- curl http://ambient-service-receive.ambient-app-receive.svc.cluster.local:8080"
echo ""

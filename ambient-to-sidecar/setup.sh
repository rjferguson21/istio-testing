#!/bin/bash

set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
CLUSTER_SCRIPT="../cluster.sh"

echo "========================================="
echo "Istio Ambient to Sidecar Test Deployment"
echo "========================================="
echo ""

# Step 1: Create cluster
echo "Step 1/6: Creating cluster with Istio..."
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

# Step 2: Deploy sidecar-app-receive (so it's ready when ambient app starts polling)
echo ""
echo "Step 2/6: Deploying sidecar-app-receive..."
echo ""
bash "${SCRIPT_DIR}/sidecar-app-receive.sh"

echo ""
echo "Waiting for sidecar-app-receive to be fully ready..."
sleep 5

# Step 3: Deploy ambient-app-receive (so it's ready when clients start polling)
echo ""
echo "Step 3/6: Deploying ambient-app-receive..."
echo ""
bash "${SCRIPT_DIR}/ambient-app-receive.sh"

echo ""
echo "Waiting for ambient-app-receive to be fully ready..."
sleep 5

# Step 4: Deploy sidecar app client (polls ambient-app-receive)
echo ""
echo "Step 4/6: Deploying sidecar application..."
echo ""
bash "${SCRIPT_DIR}/sidecar-app.sh"

echo ""
echo "Waiting for sidecar-app to be fully ready..."
sleep 5

# Step 5: Deploy non-mesh app (demonstrates direct port 8080 traffic)
echo ""
echo "Step 5/6: Deploying non-mesh application..."
echo ""
bash "${SCRIPT_DIR}/non-mesh-app.sh"

echo ""
echo "Waiting for non-mesh-app to be fully ready..."
sleep 5

# Step 6: Deploy ambient app
echo ""
echo "Step 6/6: Deploying ambient application..."
echo ""
bash "${SCRIPT_DIR}/ambient-app.sh"

echo ""
echo "========================================="
echo " Deployment Complete!"
echo "========================================="
echo ""
echo "Summary:"
echo "  - Cluster: istio-cluster (k3d)"
echo "  - Sidecar App Receive: sidecar-app-receive namespace (sidecar proxy - server)"
echo "  - Ambient App Receive: ambient-app-receive namespace (ambient mesh - server)"
echo "  - Sidecar App: sidecar-app namespace (sidecar proxy - client)"
echo "  - Non-Mesh App: non-mesh-app namespace (NO mesh, NO sidecar - client)"
echo "  - Ambient App: ambient-app namespace (ambient mesh - client)"
echo ""
echo "Next Steps:"
echo ""
echo "1. Check ambient app logs (ambient client to sidecar/ambient servers):"
echo "   kubectl logs -f deployment/ambient-app -n ambient-app"
echo ""
echo "2. Check sidecar app logs (sidecar client to ambient server):"
echo "   kubectl logs -f deployment/sidecar-app -n sidecar-app"
echo ""
echo "3. Check non-mesh app logs (non-mesh client to ambient server):"
echo "   kubectl logs -f deployment/non-mesh-app -n non-mesh-app"
echo ""
echo "4. Check network policies:"
echo "   kubectl get networkpolicies -n ambient-app-receive"
echo "   kubectl get networkpolicies -n sidecar-app-receive"
echo ""
echo "5. Test connectivity manually:"
echo "   kubectl exec -it deployment/ambient-app -n ambient-app -- curl http://sidecar-service-receive.sidecar-app-receive.svc.cluster.local:8080"
echo "   kubectl exec -it deployment/ambient-app -n ambient-app -- curl http://ambient-service-receive.ambient-app-receive.svc.cluster.local:8080"
echo "   kubectl exec -it deployment/sidecar-app -n sidecar-app -- curl http://ambient-service-receive.ambient-app-receive.svc.cluster.local:8080"
echo "   kubectl exec -it deployment/non-mesh-app -n non-mesh-app -- curl http://ambient-service-receive.ambient-app-receive.svc.cluster.local:8080"
echo ""

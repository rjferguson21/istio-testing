#!/bin/bash

set -e

echo "Deploying sidecar-enabled client application..."

NAMESPACE="sidecar-app"
TARGET_NAMESPACE="ambient-app-receive"
TARGET_SERVICE="ambient-service-receive"

# Create namespace
echo "Creating namespace: ${NAMESPACE}..."
kubectl create namespace ${NAMESPACE} --dry-run=client -o yaml | kubectl apply -f -

# Enable sidecar injection
echo "Enabling sidecar injection for namespace..."
kubectl label namespace ${NAMESPACE} istio-injection=enabled --overwrite

# Deploy application and network policies
echo "Deploying sidecar client application..."
kubectl apply -n ${NAMESPACE} -f - <<EOF
apiVersion: v1
kind: Service
metadata:
  name: sidecar-service
  labels:
    app: sidecar-app
spec:
  ports:
  - port: 8080
    name: http
  selector:
    app: sidecar-app
---
apiVersion: apps/v1
kind: Deployment
metadata:
  name: sidecar-app
spec:
  replicas: 1
  selector:
    matchLabels:
      app: sidecar-app
  template:
    metadata:
      labels:
        app: sidecar-app
    spec:
      containers:
      - name: sidecar-app
        image: curlimages/curl:latest
        command: ["/bin/sh"]
        args:
        - -c
        - |
          while true; do
            echo "\$(date): Polling ambient-app-receive (sidecar via HBONE)..."
            if curl -s -o /dev/null -w "%{http_code}" http://${TARGET_SERVICE}.${TARGET_NAMESPACE}.svc.cluster.local:8080 | grep -q "200"; then
              echo "✓ Successfully connected to ambient-app-receive"
            else
              echo "✗ Failed to connect to ambient-app-receive"
            fi
            sleep 5
          done
        resources:
          requests:
            memory: "32Mi"
            cpu: "100m"
          limits:
            memory: "64Mi"
            cpu: "200m"
EOF

# Apply common network policies
echo "Applying common network policies..."
kubectl apply -n ${NAMESPACE} -f common/common-netpol.yaml

# Apply sidecar-app specific network policies
echo "Applying sidecar-app specific network policies..."
kubectl apply -n ${NAMESPACE} -f sidecar-app/sidecar-app-netpol.yaml

# Wait for deployment to be ready
echo "Waiting for deployment to be ready..."
kubectl wait --for=condition=Available deployment/sidecar-app -n ${NAMESPACE} --timeout=120s

# Wait for sidecar injection (check for 2 containers)
echo "Verifying sidecar injection..."
sleep 5
CONTAINER_COUNT=$(kubectl get pods -n ${NAMESPACE} -l app=sidecar-app -o jsonpath='{.items[0].spec.containers[*].name}' | wc -w)
if [ "$CONTAINER_COUNT" -eq 2 ]; then
    echo "✓ Sidecar proxy injected successfully"
else
    echo "⚠ Warning: Expected 2 containers, found ${CONTAINER_COUNT}"
fi

echo ""
echo "✓ Sidecar client application deployed successfully!"
echo ""
echo "Namespace: ${NAMESPACE} (Sidecar injection enabled)"
echo "Target: ${TARGET_SERVICE}.${TARGET_NAMESPACE}.svc.cluster.local:8080"
echo ""
echo "To view logs:"
echo "  kubectl logs -f deployment/sidecar-app -n ${NAMESPACE}"

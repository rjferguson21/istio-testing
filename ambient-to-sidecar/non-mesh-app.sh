#!/bin/bash

set -e

echo "Deploying non-mesh application..."

NAMESPACE="non-mesh-app"
TARGET_NAMESPACE="ambient-app-receive"
TARGET_SERVICE="ambient-service-receive"

# Create namespace (no mesh enrollment)
echo "Creating namespace: ${NAMESPACE}..."
kubectl create namespace ${NAMESPACE} --dry-run=client -o yaml | kubectl apply -f -

# Deploy application and network policies
echo "Deploying non-mesh application..."
kubectl apply -n ${NAMESPACE} -f - <<EOF
apiVersion: v1
kind: Service
metadata:
  name: non-mesh-service
  labels:
    app: non-mesh-app
spec:
  ports:
  - port: 8080
    name: http
  selector:
    app: non-mesh-app
---
apiVersion: apps/v1
kind: Deployment
metadata:
  name: non-mesh-app
spec:
  replicas: 1
  selector:
    matchLabels:
      app: non-mesh-app
  template:
    metadata:
      labels:
        app: non-mesh-app
    spec:
      containers:
      - name: non-mesh-app
        image: curlimages/curl:latest
        command: ["/bin/sh"]
        args:
        - -c
        - |
          while true; do
            echo "\$(date): Polling ambient-app-receive (direct, no mesh)..."
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

# Apply non-mesh-app specific network policies
echo "Applying non-mesh-app specific network policies..."
kubectl apply -n ${NAMESPACE} -f non-mesh-app/non-mesh-app-netpol.yaml

# Wait for deployment to be ready
echo "Waiting for deployment to be ready..."
kubectl wait --for=condition=Available deployment/non-mesh-app -n ${NAMESPACE} --timeout=120s

echo ""
echo "✓ Non-mesh application deployed successfully!"
echo ""
echo "Namespace: ${NAMESPACE} (NO ambient mesh, NO sidecar)"
echo "Target: ${TARGET_SERVICE}.${TARGET_NAMESPACE}.svc.cluster.local:8080"
echo ""
echo "To view logs:"
echo "  kubectl logs -f deployment/non-mesh-app -n ${NAMESPACE}"

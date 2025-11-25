#!/bin/bash

set -e

echo "Deploying ambient mesh application..."

NAMESPACE="ambient-app"
TARGET_NAMESPACE="sidecar-app"
TARGET_SERVICE="sidecar-service"
TARGET_NAMESPACE_2="ambient-app-receive"
TARGET_SERVICE_2="ambient-service-receive"

# Create namespace
echo "Creating namespace: ${NAMESPACE}..."
kubectl create namespace ${NAMESPACE} --dry-run=client -o yaml | kubectl apply -f -

# Label namespace for ambient mesh
echo "Enrolling namespace in ambient mesh..."
kubectl label namespace ${NAMESPACE} istio.io/dataplane-mode=ambient --overwrite

# Deploy application and network policies
echo "Deploying ambient application..."
kubectl apply -n ${NAMESPACE} -f - <<EOF
apiVersion: v1
kind: Service
metadata:
  name: ambient-service
  labels:
    app: ambient-app
spec:
  ports:
  - port: 8080
    name: http
  selector:
    app: ambient-app
---
apiVersion: apps/v1
kind: Deployment
metadata:
  name: ambient-app
spec:
  replicas: 1
  selector:
    matchLabels:
      app: ambient-app
  template:
    metadata:
      labels:
        app: ambient-app
    spec:
      containers:
      - name: ambient-app
        image: curlimages/curl:latest
        command: ["/bin/sh"]
        args:
        - -c
        - |
          while true; do
            echo "\$(date): Polling sidecar app..."
            if curl -s -o /dev/null -w "%{http_code}" http://${TARGET_SERVICE}.${TARGET_NAMESPACE}.svc.cluster.local:8080 | grep -q "200"; then
              echo "✓ Successfully connected to sidecar app"
            else
              echo "✗ Failed to connect to sidecar app"
            fi

            echo "\$(date): Polling ambient-app-receive..."
            if curl -s -o /dev/null -w "%{http_code}" http://${TARGET_SERVICE_2}.${TARGET_NAMESPACE_2}.svc.cluster.local:8080 | grep -q "200"; then
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

# Apply ambient-app specific network policies
echo "Applying ambient-app specific network policies..."
kubectl apply -n ${NAMESPACE} -f ambient-app/ambient-app-netpol.yaml

# Wait for deployment to be ready
echo "Waiting for deployment to be ready..."
kubectl wait --for=condition=Available deployment/ambient-app -n ${NAMESPACE} --timeout=120s

echo ""
echo "✓ Ambient application deployed successfully!"
echo ""
echo "Namespace: ${NAMESPACE}"
echo "Targets:"
echo "  - ${TARGET_SERVICE}.${TARGET_NAMESPACE}.svc.cluster.local:8080"
echo "  - ${TARGET_SERVICE_2}.${TARGET_NAMESPACE_2}.svc.cluster.local:8080"
echo ""
echo "To view logs:"
echo "  kubectl logs -f deployment/ambient-app -n ${NAMESPACE}"

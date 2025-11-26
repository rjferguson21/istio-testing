#!/bin/bash

set -e

echo "Deploying sidecar-enabled receive application..."

NAMESPACE="sidecar-app-receive"

# Create namespace
echo "Creating namespace: ${NAMESPACE}..."
kubectl create namespace ${NAMESPACE} --dry-run=client -o yaml | kubectl apply -f -

# Enable sidecar injection
echo "Enabling sidecar injection for namespace..."
kubectl label namespace ${NAMESPACE} istio-injection=enabled --overwrite

# Deploy application and network policies
echo "Deploying sidecar application..."
kubectl apply -n ${NAMESPACE} -f - <<EOF
apiVersion: v1
kind: Service
metadata:
  name: sidecar-service-receive
  labels:
    app: sidecar-app-receive
spec:
  ports:
  - port: 8080
    name: http
  selector:
    app: sidecar-app-receive
---
apiVersion: apps/v1
kind: Deployment
metadata:
  name: sidecar-app-receive
spec:
  replicas: 1
  selector:
    matchLabels:
      app: sidecar-app-receive
  template:
    metadata:
      labels:
        app: sidecar-app-receive
    spec:
      containers:
      - name: sidecar-app-receive
        image: hashicorp/http-echo:latest
        args:
        - -text=Hello from sidecar-app-receive!
        - -listen=:8080
        ports:
        - containerPort: 8080
          name: http
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

# Apply sidecar-app-receive specific network policies
echo "Applying sidecar-app-receive specific network policies..."
kubectl apply -n ${NAMESPACE} -f sidecar-app-receive/sidecar-app-receive-netpol.yaml

# Wait for deployment to be ready
echo "Waiting for deployment to be ready..."
kubectl wait --for=condition=Available deployment/sidecar-app-receive -n ${NAMESPACE} --timeout=120s

# Wait for sidecar injection (check for 2 containers)
echo "Verifying sidecar injection..."
sleep 5
CONTAINER_COUNT=$(kubectl get pods -n ${NAMESPACE} -l app=sidecar-app-receive -o jsonpath='{.items[0].spec.containers[*].name}' | wc -w)
if [ "$CONTAINER_COUNT" -eq 2 ]; then
    echo "✓ Sidecar proxy injected successfully"
else
    echo "⚠ Warning: Expected 2 containers, found ${CONTAINER_COUNT}"
fi

echo ""
echo "✓ Sidecar receive application deployed successfully!"
echo ""
echo "Namespace: ${NAMESPACE}"
echo "Service: sidecar-service-receive.${NAMESPACE}.svc.cluster.local:8080"
echo ""
echo "To view pods:"
echo "  kubectl get pods -n ${NAMESPACE}"
echo ""
echo "To test the service:"
echo "  kubectl run test-pod --rm -i --tty --image=curlimages/curl -- curl http://sidecar-service-receive.${NAMESPACE}.svc.cluster.local:8080"

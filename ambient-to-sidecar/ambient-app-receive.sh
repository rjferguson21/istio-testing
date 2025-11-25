#!/bin/bash

set -e

echo "Deploying ambient-app-receive..."

NAMESPACE="ambient-app-receive"

# Create namespace
echo "Creating namespace: ${NAMESPACE}..."
kubectl create namespace ${NAMESPACE} --dry-run=client -o yaml | kubectl apply -f -

# Label namespace for ambient mesh
echo "Enrolling namespace in ambient mesh..."
kubectl label namespace ${NAMESPACE} istio.io/dataplane-mode=ambient --overwrite

# Deploy application and network policies
echo "Deploying ambient-app-receive..."
kubectl apply -n ${NAMESPACE} -f - <<EOF
apiVersion: v1
kind: Service
metadata:
  name: ambient-service-receive
  labels:
    app: ambient-app-receive
spec:
  ports:
  - port: 8080
    name: http
  selector:
    app: ambient-app-receive
---
apiVersion: apps/v1
kind: Deployment
metadata:
  name: ambient-app-receive
spec:
  replicas: 1
  selector:
    matchLabels:
      app: ambient-app-receive
  template:
    metadata:
      labels:
        app: ambient-app-receive
    spec:
      containers:
      - name: ambient-app-receive
        image: hashicorp/http-echo:latest
        args:
        - -text=Hello from ambient-app-receive!
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

# Apply ambient-app-receive specific network policies
echo "Applying ambient-app-receive specific network policies..."
kubectl apply -n ${NAMESPACE} -f ambient-app-receive/ambient-app-receive-netpol.yaml

# Wait for deployment to be ready
echo "Waiting for deployment to be ready..."
kubectl wait --for=condition=Available deployment/ambient-app-receive -n ${NAMESPACE} --timeout=120s

echo ""
echo "✓ Ambient-app-receive deployed successfully!"
echo ""
echo "Namespace: ${NAMESPACE}"
echo "Service: ambient-service-receive.${NAMESPACE}.svc.cluster.local:8080"
echo ""
echo "To view pods:"
echo "  kubectl get pods -n ${NAMESPACE}"
echo ""
echo "To test the service:"
echo "  kubectl run test-pod --rm -i --tty --image=curlimages/curl -- curl http://ambient-service-receive.${NAMESPACE}.svc.cluster.local:8080"

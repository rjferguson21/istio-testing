#!/bin/bash

set -e

echo "Deploying sidecar-enabled application..."

NAMESPACE="sidecar-app"

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
kind: ServiceAccount
metadata:
  name: sidecar-app
---
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
      serviceAccountName: sidecar-app
      containers:
      - name: sidecar-app
        image: hashicorp/http-echo:latest
        args:
        - -text=Hello from sidecar app!
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
---
# Default deny all traffic
apiVersion: networking.k8s.io/v1
kind: NetworkPolicy
metadata:
  name: default-deny-all
spec:
  podSelector: {}
  policyTypes:
  - Ingress
  - Egress
---
# Allow ingress from ambient-app namespace to sidecar-app
apiVersion: networking.k8s.io/v1
kind: NetworkPolicy
metadata:
  name: allow-from-ambient-app
spec:
  podSelector:
    matchLabels:
      app: sidecar-app
  policyTypes:
  - Ingress
  ingress:
  - from:
    - namespaceSelector:
        matchLabels:
          kubernetes.io/metadata.name: ambient-app
    ports:
    - protocol: TCP
      port: 15008
---
# Allow sidecar egress to istio system (for control plane communication)
apiVersion: networking.k8s.io/v1
kind: NetworkPolicy
metadata:
  name: allow-istio-system-egress
spec:
  podSelector:
    matchLabels:
      app: sidecar-app
  policyTypes:
  - Egress
  egress:
  - to:
    - namespaceSelector:
        matchLabels:
          kubernetes.io/metadata.name: istio-system
  - to:
    - namespaceSelector:
        matchLabels:
          kubernetes.io/metadata.name: kube-system
    ports:
    - protocol: UDP
      port: 53
EOF

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
echo "✓ Sidecar application deployed successfully!"
echo ""
echo "Namespace: ${NAMESPACE}"
echo "Service: sidecar-service.${NAMESPACE}.svc.cluster.local:8080"
echo ""
echo "To view pods:"
echo "  kubectl get pods -n ${NAMESPACE}"
echo ""
echo "To test the service:"
echo "  kubectl run test-pod --rm -i --tty --image=curlimages/curl -- curl http://sidecar-service.${NAMESPACE}.svc.cluster.local:8080"

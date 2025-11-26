#!/bin/bash

k3d cluster delete istio-cluster

# Create a new k3d cluster but disable traefik since it conflicts with istio
k3d cluster create istio-cluster --api-port 6550 -p '9080:80@loadbalancer' -p '9443:443@loadbalancer' --agents 2 --k3s-arg '--disable=traefik@server:*'

helm install istio-base istio/base -n istio-system --create-namespace --wait

kubectl get crd gateways.gateway.networking.k8s.io &> /dev/null || \
    kubectl apply -f https://github.com/kubernetes-sigs/gateway-api/releases/download/v1.3.0/standard-install.yaml

helm install istiod istio/istiod --namespace istio-system --set profile=ambient --wait

helm install istio-cni istio/cni -n istio-system --set profile=ambient --set global.platform=k3d --wait

helm install ztunnel istio/ztunnel -n istio-system --wait

kubectl create namespace istio-ingress
kubectl label namespace istio-ingress istio.io/dataplane-mode=ambient

helm install istio-ingress istio/gateway -n istio-ingress --wait

kubectl apply -f - <<EOF
apiVersion: telemetry.istio.io/v1
kind: Telemetry
metadata:
  name: mesh-default
  namespace: istio-system
spec:
  accessLogging:
    - providers:
      - name: envoy
EOF

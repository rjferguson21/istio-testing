# Network Policies for Ambient to Sidecar Communication

This document describes the minimum required network policies to enable communication from an Istio ambient mesh namespace to a sidecar-enabled namespace under a default deny policy.

## Overview

Both namespaces ([ambient-app](ambient-app) and [sidecar-app](sidecar-app)) implement a default deny-all policy, then add specific allow rules for the minimum required traffic.

## Network Policies in sidecar-app Namespace

### 1. Default Deny All
```yaml
apiVersion: networking.k8s.io/v1
kind: NetworkPolicy
metadata:
  name: default-deny-all
  namespace: sidecar-app
spec:
  podSelector: {}
  policyTypes:
  - Ingress
  - Egress
```
Blocks all ingress and egress traffic by default.

### 2. Allow Ingress from ambient-app
```yaml
apiVersion: networking.k8s.io/v1
kind: NetworkPolicy
metadata:
  name: allow-from-ambient-app
  namespace: sidecar-app
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
```
**Key Port: 15008** - This is the **Istio HBONE (HTTP-Based Overlay Network Encapsulation)** port used by ambient mesh to communicate with sidecar proxies.

### 3. Allow Egress to Istio Control Plane
```yaml
apiVersion: networking.k8s.io/v1
kind: NetworkPolicy
metadata:
  name: allow-istio-system-egress
  namespace: sidecar-app
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
```
Allows the sidecar proxy to communicate with Istio control plane (istiod) and DNS.

## Network Policies in ambient-app Namespace

### 1. Default Deny All
```yaml
apiVersion: networking.k8s.io/v1
kind: NetworkPolicy
metadata:
  name: default-deny-all
  namespace: ambient-app
spec:
  podSelector: {}
  policyTypes:
  - Ingress
  - Egress
```
Blocks all ingress and egress traffic by default.

### 2. Allow Egress to sidecar-app
```yaml
apiVersion: networking.k8s.io/v1
kind: NetworkPolicy
metadata:
  name: allow-to-sidecar-app
  namespace: ambient-app
spec:
  podSelector:
    matchLabels:
      app: ambient-app
  policyTypes:
  - Egress
  egress:
  - to:
    - namespaceSelector:
        matchLabels:
          kubernetes.io/metadata.name: sidecar-app
    ports:
    - protocol: TCP
      port: 15008
```
**Key Port: 15008** - Allows egress to the sidecar-app namespace on the HBONE port.

### 3. Allow Egress to Istio System
```yaml
apiVersion: networking.k8s.io/v1
kind: NetworkPolicy
metadata:
  name: allow-istio-system-egress
  namespace: ambient-app
spec:
  podSelector:
    matchLabels:
      app: ambient-app
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
```
Allows the ambient app to communicate with Istio ambient components (ztunnel) and DNS.

## Critical Port: 15008

The **most important discovery** is that port **15008** is required for ambient-to-sidecar communication. This port is used for:

- **HBONE (HTTP-Based Overlay Network Encapsulation)** - Istio's ambient mesh protocol
- The ztunnel (in ambient-app namespace) encapsulates traffic and sends it to the sidecar proxy on port 15008
- The sidecar proxy (in sidecar-app namespace) receives the encapsulated traffic, decapsulates it, and forwards it to the application

## Traffic Flow

```
ambient-app pod
    ↓ (HTTP request to sidecar-service:8080)
ztunnel (ambient mesh, in ambient-app namespace)
    ↓ (Encapsulates via HBONE)
    ↓ TCP 15008
istio-proxy sidecar (in sidecar-app pod)
    ↓ (Decapsulates and forwards)
sidecar-app container :8080
```

## Minimum Requirements Summary

For ambient → sidecar communication, you need:

1. **Ingress to sidecar namespace**: Port 15008 from ambient namespace
2. **Egress from ambient namespace**: Port 15008 to sidecar namespace
3. **Both namespaces**: Egress to istio-system (for control plane) and kube-system:53 (DNS)

## Testing

Verify the policies are working:
```bash
# Check network policies
kubectl get networkpolicies -n ambient-app
kubectl get networkpolicies -n sidecar-app

# Check logs - should show successful connections
kubectl logs -f deployment/ambient-app -n ambient-app
```

## Notes

- Port 8080 is NOT required in the network policies because traffic is encapsulated by Istio
- The application uses port 8080, but at the network policy level, only port 15008 (HBONE) is needed
- Without these specific policies allowing port 15008, communication would fail even though Istio is configured correctly

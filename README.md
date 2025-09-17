# Podinfo Testing with Network Policies

## Setup Instructions

1. **Create the cluster:**
   ```bash
   ./cluster.sh
   ```

2. **Deploy podinfo:**
   ```bash
   cd podinfo && ./podinfo.sh
   ```

3. **Port-forward the frontend service:**
   ```bash
   kubectl port-forward -n podinfo svc/frontend-podinfo 9898:9898
   ```

4. **Test connectivity:**
   ```bash
   ./podinfo/test.sh
   ```

## Network Policies

The setup includes network policies that:
- Deny all traffic by default (`default-deny-networkpolicy.yaml`)
- Allow DNS resolution (`allow-dns.yaml`)
- Allow frontend-to-backend communication on ports 9898 and 15008 (HBONE) (`allow-frontend-to-backend-hbone.yaml`)
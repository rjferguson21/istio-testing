
kubectl create ns podinfo
kubectl label namespace podinfo istio.io/dataplane-mode=ambient

helm upgrade --install --wait frontend \
    --namespace podinfo \
    --set replicaCount=2 \
    --set backend=http://backend-podinfo:9898/echo \
    podinfo/podinfo

helm upgrade --install --wait backend \
    --namespace podinfo \
    --set redis.enabled=true \
    podinfo/podinfo

kubectl apply -f default-deny-networkpolicy.yaml -n podinfo
kubectl apply -f allow-frontend-to-backend-hbone.yaml -n podinfo
kubectl apply -f allow-dns.yaml -n podinfo

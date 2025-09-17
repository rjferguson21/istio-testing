#!/bin/bash
kubectl create namespace bookinfo
kubectl label namespace bookinfo istio.io/dataplane-mode=ambient

kubectl apply -f https://raw.githubusercontent.com/istio/istio/release-1.27/samples/bookinfo/platform/kube/bookinfo.yaml -n bookinfo
kubectl apply -f https://raw.githubusercontent.com/istio/istio/release-1.27/samples/bookinfo/platform/kube/bookinfo-versions.yaml -n bookinfo

# gateway
kubectl apply -f https://raw.githubusercontent.com/istio/istio/release-1.27/samples/bookinfo/gateway-api/bookinfo-gateway.yaml -n bookinfo 
kubectl annotate gateway bookinfo-gateway networking.istio.io/service-type=ClusterIP --namespace=bookinfo

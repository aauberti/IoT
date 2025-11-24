#!/bin/bash

set -e

k3d cluster delete iot-p3
# Create Inital k3d cluster
k3d cluster create iot-p3

# Set an argocd namespace and install argocd
kubectl create namespace argocd
kubectl create namespace dev
kubectl apply -n argocd -f https://raw.githubusercontent.com/argoproj/argo-cd/stable/manifests/install.yaml

echo "Waiting for argocd-server pod to be Ready..."
kubectl wait --for=condition=ready pod -l app.kubernetes.io/name=argocd-server -n argocd --timeout=180s
kubectl port-forward svc/argocd-server -n argocd 8080:443 >/tmp/argocd-pf.log 2>&1 & PF_PID=$!

# Get password
echo "Waiting initial-password secret to be set"
until kubectl -n argocd get secret argocd-initial-admin-secret >/dev/null 2>&1; do
	sleep 2
done
PASSWORD=$(argocd admin initial-password -n argocd)
echo $PASSWORD
argocd login localhost:8080 --username admin --password "$PASSWORD" --insecure
argocd account update-password

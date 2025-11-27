#!/bin/bash

set -e

# CLean previous launch and Create Inital k3d cluster
pkill -f "kubectl port-forward svc/argocd-server" || true
k3d cluster delete iot-p3
k3d cluster create iot-p3

# Set namespaces
kubectl create namespace argocd
kubectl create namespace dev

# Handle docker limit pull rate
kubectl create secret docker-registry regcred --from-file=.dockerconfigjson=$HOME/.docker/config.json -n default
kubectl create secret docker-registry regcred --from-file=.dockerconfigjson=$HOME/.docker/config.json -n dev
kubectl create secret docker-registry regcred --from-file=.dockerconfigjson=$HOME/.docker/config.json -n argocd
kubectl patch serviceaccount default -p '{"imagePullSecrets":[{"name":"regcred"}]}' -n dev
kubectl patch serviceaccount default -p '{"imagePullSecrets":[{"name":"regcred"}]}' -n argocd

# Install Argocd
kubectl apply -n argocd -f https://raw.githubusercontent.com/argoproj/argo-cd/stable/manifests/install.yaml

# Set port forwarding
echo "Waiting for argocd-server pod to be Ready..."
kubectl wait --for=condition=ready pod -l app.kubernetes.io/name=argocd-server -n argocd --timeout=180s
kubectl port-forward svc/argocd-server -n argocd 8080:443 >/tmp/argocd-pf.log 2>&1 & PF_PID=$!
while ! nc -z localhost 8080; do
    sleep 1
done

# Set a new password
echo "Waiting initial-password secret to be set"
until kubectl -n argocd get secret argocd-initial-admin-secret -o jsonpath="{.data.password}" 2>/dev/null | grep -q .; do
	sleep 2
done
PASSWORD=$(kubectl -n argocd get secret argocd-initial-admin-secret -o jsonpath="{.data.password}" | base64 -d)
echo $PASSWORD
argocd login localhost:8080 --username admin --password "$PASSWORD" --insecure
NEW_PASSWORD="Qwerty12345"
argocd account update-password --current-password "$PASSWORD" --new-password "$NEW_PASSWORD"

# Add repo, create app and sync it
argocd repo add https://github.com/aauberti/IoT-Manifest_p3.git
argocd app create wil --repo https://github.com/aauberti/IoT-Manifest_p3.git --path "./" --dest-server https://kubernetes.default.svc --dest-namespace dev --sync-policy automated
echo "Waiting for the wil app to be ready"
argocd app wait wil --health --timeout 180
echo "You can set port forwarding with kubectl port-forward deployment/wil -n dev 8888:8888"

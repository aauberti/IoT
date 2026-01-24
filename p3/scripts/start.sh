#!/bin/bash

set -e

BLUE="\e[1;34m"
RESET="\e[0m"
BOLD="\033[1m"
NORMAL="\033[0m"

## CLean previous launch
pkill -f "kubectl port-forward svc/argocd-server" || true
k3d cluster delete iot

## Checking docker connection
if [ ! -f "$HOME/.docker/config.json" ]; then
	echo "Error: Docker config file not found at $HOME/.docker/config.json"
	echo 'Please login to docker first with `docker login`'
	exit 1
fi
if ! jq -e '.auths["https://index.docker.io/v1/"]' $HOME/.docker/config.json > /dev/null; then
	echo 'Please login to docker first with `docker login`'
	exit 1
fi

## Create Inital k3d cluster
k3d cluster create iot \
	--port "8888:30088@loadbalancer"

## Set namespaces
kubectl create namespace argocd
kubectl create namespace dev

## Handle docker limit pull rate
kubectl create secret docker-registry regcred --from-file=.dockerconfigjson=$HOME/.docker/config.json -n default
kubectl create secret docker-registry regcred --from-file=.dockerconfigjson=$HOME/.docker/config.json -n dev
kubectl create secret docker-registry regcred --from-file=.dockerconfigjson=$HOME/.docker/config.json -n argocd
kubectl patch serviceaccount default -p '{"imagePullSecrets":[{"name":"regcred"}]}' -n dev
kubectl patch serviceaccount default -p '{"imagePullSecrets":[{"name":"regcred"}]}' -n argocd

## Install Argocd
kubectl apply -n argocd -f https://raw.githubusercontent.com/argoproj/argo-cd/stable/manifests/install.yaml

## Set port forwarding
echo "Waiting for argocd-server pod to be ready..."
kubectl wait --for=condition=ready pod -l app.kubernetes.io/name=argocd-server -n argocd --timeout=500s
kubectl port-forward svc/argocd-server -n argocd 8080:443 >/tmp/argocd-pf.log 2>&1 & PF_PID=$!
while ! nc -z localhost 8080; do
	sleep 1
done

## Login and get admin password
echo "Waiting initial-password secret to be set"
until kubectl -n argocd get secret argocd-initial-admin-secret -o jsonpath="{.data.password}" 2>/dev/null | grep -q .; do
	sleep 2
done
PASSWORD=$(kubectl -n argocd get secret argocd-initial-admin-secret -o jsonpath="{.data.password}" | base64 -d)
argocd login localhost:8080 --username admin --password "$PASSWORD" --insecure
echo -e "\n${BLUE}You can login to Argo CD from: localhost:8080\nUse the folowing creadentials: ${BOLD}admin:$PASSWORD${NORMAL}${RESET}\n"

## Add repo, create app and sync it
argocd repo add https://github.com/k0d3K/IoT-Manifest_p3.git
argocd app create wil --repo https://github.com/k0d3K/IoT-Manifest_p3.git --path "./" --dest-server https://kubernetes.default.svc --dest-namespace dev --sync-policy automated
echo "Waiting for the wil app to be ready"
argocd app wait wil --health --timeout 180

echo -e "\n${BLUE}Wil app ready on: ${BOLD}localhost:8888${NORMAL}\n"

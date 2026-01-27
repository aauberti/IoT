#!/bin/bash

set -e

GREEN="\e[92m"
RESET="\e[0m"

##Checking cluster iot it up
if ! k3d cluster list | grep -q '^iot'; then
	echo "Error: Cluster K3D not set, please run part 3 first"
	exit 1
fi

## Set the domain to the local host
GITLAB_DOMAIN="k3d.local"
sudo sed -i '/k3d.local/d' /etc/hosts
echo "127.0.0.1 gitlab.${GITLAB_DOMAIN}" | sudo tee -a /etc/hosts
echo "127.0.0.1 registry.${GITLAB_DOMAIN}" | sudo tee -a /etc/hosts
echo "127.0.0.1 minio.${GITLAB_DOMAIN}" | sudo tee -a /etc/hosts

## Intall Helm -> do not install if already installed
command -v helm >/dev/null 2>&1 || curl https://raw.githubusercontent.com/helm/helm/main/scripts/get-helm-4 | bash

## Set the namespace
kubectl delete namespace gitlab --ignore-not-found
kubectl create namespace gitlab

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

## Add secret token Docker
kubectl create secret docker-registry regcred --from-file=.dockerconfigjson=$HOME/.docker/config.json -n gitlab
kubectl patch serviceaccount default -p '{"imagePullSecrets":[{"name":"regcred"}]}' -n gitlab

## Install GitLab instance
helm repo add gitlab https://charts.gitlab.io/
helm repo update
helm upgrade --install gitlab gitlab/gitlab \
	-n gitlab \
	-f conf/gitlab-values.yaml \
	--timeout 1200s \
	--set global.hosts.domain=${GITLAB_DOMAIN} \
	--set global.hosts.externalIP=127.0.0.1 \
	--set global.hosts.https=false
kubectl wait --for=condition=ready --timeout=1200s pod -l app=webservice -n gitlab

## Get password
GITLAB_PSSWD=$(kubectl get secret gitlab-gitlab-initial-root-password -n gitlab -ojsonpath='{.data.password}' | base64 -d)
echo $GITLAB_PSSWD > gitlab-password.txt

## Ready Message
echo -e "\n${GREEN}Gitlab server is running. Launch update.sh script to add a new repository to Argo CD${RESET}\n"

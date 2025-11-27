#!/bin/bash

set -e

## Set the domain to the local host
GITLAB_DOMAIN="k3d.local"
sudo sed -i '/k3d.local/d' /etc/hosts
echo "127.0.0.1 gitlab.${GITLAB_DOMAIN}" | sudo tee -a /etc/hosts
echo "127.0.0.1 registry.${GITLAB_DOMAIN}" | sudo tee -a /etc/hosts
echo "127.0.0.1 minio.${GITLAB_DOMAIN}" | sudo tee -a /etc/hosts


## Intall Helm
curl https://raw.githubusercontent.com/helm/helm/main/scripts/get-helm-4 | bash


## Set the namespace
kubectl create namespace gitlab

## Add secret token Docker
kubectl create secret docker-registry regcred --from-file=.dockerconfigjson=$HOME/.docker/config.json -n gitlab
kubectl patch serviceaccount default -p '{"imagePullSecrets":[{"name":"regcred"}]}' -n gitlab

## Install GitLab instance
helm repo add gitlab https://charts.gitlab.io/
helm repo update
helm upgrade --install gitlab gitlab/gitlab \
  -n gitlab \
  -f https://gitlab.com/gitlab-org/charts/gitlab/raw/master/examples/values-minikube-minimum.yam \
  --timeout 900s \
  --set global.hosts.domain=${GITLAB_DOMAIN} \
  --set global.hosts.externalIP=127.0.0.1 \
  --set global.hosts.hhtps=false
kubectl wait --for=condition=ready --timeout=1200s pod -l app=webservice -n gitlab

## Get password
GITLAB_PSSWD=$(kubectl get secret gitlab-gitlab-initial-root-password -n gitlab -ojsonpath='{.data.password}' | base64 -d)
echo $GITLAB_PSSWD > gitlab-password.txt


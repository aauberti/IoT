#!/bin/bash

set -e

GREEN="\e[92m"
RESET="\e[0m"
BOLD="\033[1m"
NORMAL="\033[0m"

GITLAB_URL="http://gitlab.k3d.local:8181"
GITLAB_REPO="IoT-Manifest_bonus"
GITLAB_PASSWORD=$(cat gitlab-password.txt)
GITLAB_SERVICE_URL="http://gitlab-webservice-default.gitlab.svc.cluster.local:8181"

## Set port forwarding to gitlab
echo "==> Starting GitLab port-forward..."
pkill -f "kubectl port-forward svc/gitlab-webservice-default" || true
kubectl port-forward svc/gitlab-webservice-default -n gitlab 8181:8181 >/tmp/gitlab-pf.log 2>&1 &

## Copy files from github
rm -rf IoT-Manifest_p3 IoT-Manifest_bonus
git clone https://github.com/k0d3K/IoT-Manifest_p3.git

## Create repo and move inside
mkdir $GITLAB_REPO && cd $GITLAB_REPO
cp ../IoT-Manifest_p3/*.yaml .
git init --initial-branch=main
git config --local user.email "admin@k3d.local"
git config --local user.name "Administrator"
git add .
git commit -m "Chore: copy repo from Github"
git remote add origin http://root:${GITLAB_PASSWORD}@gitlab.k3d.local:8181/root/${GITLAB_REPO}.git 
git push -u origin main

## Cleanup
cd ..
rm -rf IoT-Manifest_p3

## Update repo and app
argocd repo rm https://github.com/k0d3K/IoT-Manifest_p3.git
argocd repo add ${GITLAB_SERVICE_URL}/root/${GITLAB_REPO}.git \
	--username root\
	--password ${GITLAB_PASSWORD}\
	--insecure-skip-server-verification
argocd app set wil --repo ${GITLAB_SERVICE_URL}/root/${GITLAB_REPO}.git
echo -e "\n${GREEN}Repository updated on Argo CD, you can stil access it from: ${BOLD}localhost:8080${NORMAL}${RESET}\n"

## Sync the app
argocd app sync wil
echo "Waiting for the wil app to be ready"
argocd app wait wil --health --timeout 180

echo -e "\n${GREEN}Wil app ready on: ${BOLD}localhost:8888${NORMAL}${RESET}\n"

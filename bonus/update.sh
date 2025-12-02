#!/bin/bash

set -e

GITLAB_URL=http://gitlab.k3d.local:8181
GITLAB_REPO=IoT-Manifest_bonus
GITLAB_PASSWORD=$(cat gitlab-password.txt)
GITLAB_SERVICE_URL=http://gitlab-webservice-default.gitlab.svc.cluster.local:8181

## Copy files from github
git clone https://github.com/aauberti/IoT-Manifest_p3

## Create repo and move inside
mkdir $GITLAB_REPO && cd $GITLAB_REPO
cp ../IoT-Manifest_p3/*.yaml .
git init
git add .
git commit -m "Chore: copy repo from Github"
git remote add origin http://root:${GITLAB_PASSWORD}@gitlab.k3d.local:8181/root/${GITLAB_REPO}.git 
git push --set-upstream origin master
#git push

## Cleanup
cd ..
rm -rf IoT-Manifest_p3

## update argoCD
argocd repo rm https://github.com/aauberti/IoT-Manifest_p3.git
argocd repo add ${GITLAB_SERVICE_URL}/root/${GITLAB_REPO}.git\
	--username root\
	--password ${GITLAB_PASSWORD}\
	--insecure-skip-server-verification
echo "Repo added"
argocd app set wil --repo ${GITLAB_SERVICE_URL}/root/${GITLAB_REPO}.git
echo "Repo set"
argocd app sync wil
echo "Waiting for the wil app to be ready"
argocd app wait wil --health --timeout 180
echo "You can set port forwarding with kubectl port-forward deployment/wil -n dev 8888:8888"

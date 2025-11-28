#!/bin/bash

set -e

GITLAB_URL=http://gitlab.k3d.local:8181
GITLAB_REPO=IoT-Manifest_bonus
GITLAB_PASSWORD=$(cat gitlab-password.txt)

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



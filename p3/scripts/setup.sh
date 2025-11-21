#!/bin/bash

set -e

BLUE="\e[1;34m"
RESET="\e[0m"

## Docker Installation
echo "\n$BLUE#########################"
echo "## DOCKER INSTALLATION ##"
echo "#########################$RESET\n"
sudo apt update
sudo apt install ca-certificates curl
sudo install -m 0755 -d /etc/apt/keyrings
sudo curl -fsSL https://download.docker.com/linux/debian/gpg -o /etc/apt/keyrings/docker.asc
sudo chmod a+r /etc/apt/keyrings/docker.asc
sudo tee /etc/apt/sources.list.d/docker.sources <<EOF
Types: deb
URIs: https://download.docker.com/linux/debian
Suites: $(. /etc/os-release && echo "$VERSION_CODENAME")
Components: stable
Signed-By: /etc/apt/keyrings/docker.asc
EOF
sudo apt update
sudo apt install docker-ce docker-ce-cli containerd.io docker-buildx-plugin docker-compose-plugin
sudo usermod -aG docker $USER

## K3D Installation
echo "\n$BLUE######################"
echo "## K3D INSTALLATION ##"
echo "######################$RESET\n"
curl -s https://raw.githubusercontent.com/k3d-io/k3d/main/install.sh | bash

## Kubctl Installation
echo "\n$BLUE##########################"
echo "## KUBECTL INSTALLATION ##"
echo "##########################$RESET\n"
curl -LO "https://dl.k8s.io/release/$(curl -L -s https://dl.k8s.io/release/stable.txt)/bin/linux/amd64/kubectl"
sudo install -o root -g root -m 0755 kubectl /usr/local/bin/kubectl
rm kubectl

## Verification
echo "\n$BLUE########################"
echo "## SETUP VERIFICATION ##"
echo "########################$RESET\n"
docker --version
k3d --version
kubectl version --client

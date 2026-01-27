#!/bin/bash

set -e

BLUE="\e[1;34m"
RESET="\e[0m"

## Detect OS (Ubuntu or Debian)
. /etc/os-release
OS_ID=$ID
echo -e "${BLUE}Detected OS: ${OS_ID} ${VERSION_CODENAME}${RESET}\n"

## Docker Installation
echo -e "\n${BLUE}#########################"
echo "## DOCKER INSTALLATION ##"
echo -e "#########################${RESET}\n"
sudo apt update
sudo apt install -y ca-certificates curl
sudo install -m 0755 -d /etc/apt/keyrings
sudo curl -fsSL https://download.docker.com/linux/${OS_ID}/gpg -o /etc/apt/keyrings/docker.asc
sudo chmod a+r /etc/apt/keyrings/docker.asc
sudo tee /etc/apt/sources.list.d/docker.sources <<EOF
Types: deb
URIs: https://download.docker.com/linux/${OS_ID}
Suites: ${VERSION_CODENAME}
Components: stable
Signed-By: /etc/apt/keyrings/docker.asc
EOF
sudo apt update
sudo apt install -y docker-ce docker-ce-cli containerd.io docker-buildx-plugin docker-compose-plugin
sudo usermod -aG docker $USER

## K3D Installation
echo -e "\n${BLUE}######################"
echo "## K3D INSTALLATION ##"
echo -e "######################${RESET}\n"
curl -s https://raw.githubusercontent.com/k3d-io/k3d/main/install.sh | bash

## Kubctl Installation
echo -e "\n${BLUE}##########################"
echo "## KUBECTL INSTALLATION ##"
echo -e "##########################${RESET}\n"

CURRENT_VERSION=$(kubectl version --client | grep 'Client' | awk '{print $3}')
MINIMAL_REQUIRED_VERSION="v1.35.0"
if [ -z "$CURRENT_VERSION" ] || [ "$(printf "%s\n%s\n" "$MINIMAL_REQUIRED_VERSION" "$CURRENT_VERSION" | sort -V | tail -n1)" != "$MINIMAL_REQUIRED_VERSION" ]; then
	curl -LO "https://dl.k8s.io/release/$(curl -L -s https://dl.k8s.io/release/stable.txt)/bin/linux/amd64/kubectl"
	sudo install -o root -g root -m 0755 kubectl /usr/local/bin/kubectl
	rm kubectl
else
	echo "kubectl already installed"
fi

## ArgoCD Installation
echo -e "\n${BLUE}#########################"
echo "## ARGOCD INSTALLATION ##"
echo -e "#########################${RESET}\n"
CURRENT_VERSION=$(argocd version --client --short | awk '{print $2}' | cut -d+ -f1)
MINIMAL_REQUIRED_VERSION="v3.2.6"
if [ -z "$CURRENT_VERSION" ] || [ "$(printf "%s\n%s\n" "$MINIMAL_REQUIRED_VERSION" "$CURRENT_VERSION" | sort -V | tail -n1)" != "$MINIMAL_REQUIRED_VERSION" ]; then
	curl -SL -o argocd-linux-amd64 https://github.com/argoproj/argo-cd/releases/latest/download/argocd-linux-amd64
	sudo install -m 555 argocd-linux-amd64 /usr/local/bin/argocd
	rm argocd-linux-amd64
else
	echo "argocd already installed"
fi

## Verification
echo -e "\n${BLUE}########################"
echo "## SETUP VERIFICATION ##"
echo -e "########################${RESET}\n"
docker --version
k3d --version
kubectl version --client
argocd version 2>&1 | head -n 1

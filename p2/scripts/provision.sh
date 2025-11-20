#!/bin/bash

curl -sfL https://get.k3s.io | sudo sh -s - --node-ip=192.168.56.110 --write-kubeconfig-mode 664

kubectl apply -f /vagrant/manifest/app1/app1-deployment.yaml
kubectl apply -f /vagrant/manifest/app1/app1-service.yaml
kubectl apply -f /vagrant/manifest/app2/app2-deployment.yaml
kubectl apply -f /vagrant/manifest/app2/app2-service.yaml
kubectl apply -f /vagrant/manifest/app3/app3-deployment.yaml
kubectl apply -f /vagrant/manifest/app3/app3-service.yaml
kubectl apply -f /vagrant/manifest/ingress.yaml

echo "alias k='kubectl'" >> /home/vagrant/.bashrc
sudo chown vagrant:vagrant /home/vagrant/.bashrc

sudo chmod -x /etc/update-motd.d/*

cat << 'EOF' | sudo tee /etc/update-motd.d/99-custom > /dev/null
#!/bin/sh

echo "========================================="
echo "          VM Kubernetes Vagrant"
echo "========================================="
echo ""
echo "Show nodes:"
echo "  k get nodes -o wide"
echo ""
echo "Show all components:"
echo "	k get all"
echo ""
echo "Create alias k=kubectl"
echo ""
EOF

sudo chmod +x /etc/update-motd.d/99-custom


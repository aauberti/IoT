#!/bin/bash

until ip addr | grep -q "192.168.56.110"; do
	sleep 2
done

IFACE=$(ip -o addr show | grep "192.168.56.110" | awk '{print $2}')

curl -sfL https://get.k3s.io | sudo sh -s - \
	--node-ip=192.168.56.110 \
	--flannel-iface=$IFACE \
	--write-kubeconfig-mode 644

sudo cat /var/lib/rancher/k3s/server/node-token > /vagrant/k3s-token
 
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
echo "	k get nodes -o wide"
echo ""
echo "Create alias k=kubectl"
echo ""
EOF

sudo chmod +x /etc/update-motd.d/99-custom


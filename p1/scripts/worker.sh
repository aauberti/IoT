#!/bin/bash

while [ ! -f /vagrant/k3s-token ]; do
	sleep 2
done
      
until ip addr | grep -q "192.168.56.111"; do
        sleep 2
done
      
IFACE=$(ip -o addr show | grep "192.168.56.111" | awk '{print $2}')
      
K3S_TOKEN=$(cat /vagrant/k3s-token)
curl -sfL https://get.k3s.io | K3S_URL=https://192.168.56.110:6443 \
	K3S_TOKEN=$K3S_TOKEN sh -s - agent \
        --node-ip=192.168.56.111 \
        --flannel-iface=$IFACE

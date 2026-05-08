#!/bin/bash
# p2/scripts/setup.sh
set -e

echo "[INFO] Installing K3s..."
curl -sfL https://get.k3s.io | INSTALL_K3S_EXEC="--write-kubeconfig-mode 644" sh -

echo "[INFO] Configuring kubectl access for vagrant user..."
mkdir -p /home/vagrant/.kube
cp /etc/rancher/k3s/k3s.yaml /home/vagrant/.kube/config
chown -R vagrant:vagrant /home/vagrant/.kube
chmod 600 /home/vagrant/.kube/config
cat >/etc/profile.d/k3s-kubeconfig.sh <<'EOF'
export KUBECONFIG=/home/vagrant/.kube/config
EOF
chmod 644 /etc/profile.d/k3s-kubeconfig.sh

echo "[INFO] Waiting for K3s node to be Ready..."
until kubectl get nodes 2>/dev/null | grep -q "Ready"; do
  echo "   still waiting..."; sleep 5
done

echo "[INFO] Applying manifests..."
kubectl apply -f /vagrant/confs/

echo "[INFO] Done. Cluster state:"
kubectl get nodes -o wide
kubectl get pods
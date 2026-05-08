#!/bin/bash
set -e

echo "[INFO] Installing Docker..."
curl -fsSL https://get.docker.com | sh
usermod -aG docker vagrant          # allow vagrant user to run docker
newgrp docker                       # apply group without logout

echo "[INFO] Installing kubectl..."
curl -LO "https://dl.k8s.io/release/$(curl -sL https://dl.k8s.io/release/stable.txt)/bin/linux/amd64/kubectl"
chmod +x kubectl
mv kubectl /usr/local/bin/kubectl

echo "[INFO] Installing K3d..."
curl -s https://raw.githubusercontent.com/k3d-io/k3d/main/install.sh | bash

echo "[INFO] Creating K3d cluster..."
k3d cluster create iotcluster \
  --port "8888:8888@loadbalancer"

echo "[INFO] Waiting for cluster to be ready..."
until kubectl get nodes 2>/dev/null | grep -q "Ready"; do
  echo "   still waiting..."; sleep 5
done

echo "[INFO] Creating namespaces..."
kubectl create namespace argocd
kubectl create namespace dev

echo "[INFO] Installing Argo CD..."
kubectl apply -n argocd \
  -f https://raw.githubusercontent.com/argoproj/argo-cd/stable/manifests/install.yaml

echo "[INFO] Waiting for Argo CD to be ready..."
kubectl wait --for=condition=available \
  deployment/argocd-server \
  -n argocd \
  --timeout=120s

echo "[INFO] Applying Argo CD Application config..."
kubectl apply -f /vagrant/confs/application.yaml

echo ""
echo "[INFO] Setup complete!"
echo "[INFO] Namespaces:"
kubectl get ns
echo ""
echo "[INFO] Argo CD pods:"
kubectl get pods -n argocd
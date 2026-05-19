#!/bin/bash
set -e

SCRIPT_DIR="$(cd "$(dirname "$(realpath "$0")")/.." && pwd)"

echo "[INFO] Installing dependencies..."
apt-get update -qq
apt-get install -y -qq curl


echo "[INFO] Installing Docker..."
if command -v docker >/dev/null 2>&1; then
  echo "[INFO] Docker is already installed - skipping"
else
  curl -fsSL https://get.docker.com | sh
fi

if [ -n "${SUDO_USER:-}" ] && [ "${SUDO_USER}" != "root" ] && id -u "${SUDO_USER}" >/dev/null 2>&1; then
  usermod -aG docker "${SUDO_USER}"
fi

echo "[INFO] Installing kubectl..."
if command -v kubectl >/dev/null 2>&1; then
  echo "[INFO] kubectl is already installed - skipping"
else
  curl -LO "https://dl.k8s.io/release/$(curl -sL https://dl.k8s.io/release/stable.txt)/bin/linux/amd64/kubectl"
  chmod +x kubectl
  mv kubectl /usr/local/bin/kubectl
fi

echo "[INFO] Installing K3d..."
if command -v k3d >/dev/null 2>&1; then
  echo "[INFO] k3d is already installed - skipping"
else
  curl -s https://raw.githubusercontent.com/k3d-io/k3d/main/install.sh | bash
fi

echo "[INFO] Creating K3d cluster..."
if k3d cluster list | grep -q "^iotcluster\b" 2>/dev/null; then
  echo "[INFO] k3d cluster 'iotcluster' already exists - skipping creation"
else
  k3d cluster create iotcluster \
    --port "8888:8888@loadbalancer"
fi

echo "[INFO] Waiting for cluster to be ready..."
until kubectl get nodes 2>/dev/null | grep -q "Ready"; do
  echo "   still waiting..."
  sleep 5
done

echo "[INFO] Creating namespaces..."
kubectl get namespace argocd >/dev/null 2>&1 || kubectl create namespace argocd
kubectl get namespace dev >/dev/null 2>&1 || kubectl create namespace dev

echo "[INFO] Installing Argo CD..."
kubectl apply -n argocd \
  -f https://raw.githubusercontent.com/argoproj/argo-cd/stable/manifests/install.yaml \
  --server-side \
  --force-conflicts

echo "[INFO] Waiting for Argo CD to be ready (up to 5 min)..."
kubectl wait --for=condition=available \
  deployment/argocd-server \
  -n argocd \
  --timeout=300s

echo "[INFO] Applying Argo CD Application config..."
kubectl apply -f "${SCRIPT_DIR}/confs/application.yaml"

echo ""
echo "[INFO] Setup complete!"
kubectl get ns
echo ""
kubectl get pods -n argocd

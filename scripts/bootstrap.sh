#!/usr/bin/env bash
set -euo pipefail

HOST=${HOST:-192.168.2.101}
BOX_USER=${BOX_USER:-martinsedd}
DEPLOY_KEY=${DEPLOY_KEY:-$HOME/.ssh/homeserver-argocd}
REPO=${REPO:-$(cd "$(dirname "$0")/.." && pwd)}
export KUBECONFIG=${KUBECONFIG:-$HOME/.kube/homeserver.yaml}

argocd_version=v3.5.5
sealed_version=v0.40.0

echo "== kubeconfig"
mkdir -p "$(dirname "$KUBECONFIG")"
ssh "$BOX_USER@$HOST" 'sudo cat /etc/rancher/k3s/k3s.yaml' | sed "s/127.0.0.1/$HOST/" > "$KUBECONFIG"
chmod 600 "$KUBECONFIG"

echo "== sealed-secrets"
kubectl apply -f "https://github.com/bitnami/sealed-secrets/releases/download/$sealed_version/controller.yaml"

if [ -n "${SEALED_KEY_FILE:-}" ]; then
  echo "== restoring the sealing key"
  kubectl apply -f "$SEALED_KEY_FILE"
  kubectl -n kube-system rollout restart deploy/sealed-secrets-controller
fi

kubectl -n kube-system rollout status deploy/sealed-secrets-controller --timeout=300s

echo "== argocd"
kubectl create namespace argocd --dry-run=client -o yaml | kubectl apply -f -
kubectl apply -n argocd -f "https://raw.githubusercontent.com/argoproj/argo-cd/$argocd_version/manifests/install.yaml"
kubectl -n argocd rollout status deploy/argocd-server --timeout=300s

echo "== repo credentials"
kubectl -n argocd create secret generic homeserver-infra \
  --from-literal=type=git \
  --from-literal=url=git@github.com:martinsedd/homeserver-infra.git \
  --from-file=sshPrivateKey="$DEPLOY_KEY" \
  --dry-run=client -o yaml | kubectl apply -f -
kubectl -n argocd label secret homeserver-infra argocd.argoproj.io/secret-type=repository --overwrite

echo "== root application"
kubectl apply -f "$REPO/cluster/bootstrap/app-of-apps.yaml"

echo "bootstrap complete"

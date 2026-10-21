#!/usr/bin/env bash
set -euo pipefail

HOST=${HOST:-192.168.2.101}
BOX_USER=${BOX_USER:-martinsedd}
REPO=${REPO:-$(cd "$(dirname "$0")/.." && pwd)}
AGE_KEY=${AGE_KEY:-$HOME/.config/sops/age/homeserver.txt}

cat <<'EOF'
This wipes the server's system disk and rebuilds it from the flake.
Prerequisites:
  - the NixOS minimal ISO is booted on the server
  - sshd is running and root login is possible (set a root password in the live environment)
  - the USB backup drive is attached
  - you have the sops age key and the SealedSecrets key backup at hand
EOF

read -r -p "Type WIPE to continue: " confirm
[ "$confirm" = "WIPE" ] || { echo "aborted"; exit 1; }

read -r -p "Path to the SealedSecrets key backup (leave empty to skip): " SEALED_KEY_FILE
read -r -p "Path to your age key [$AGE_KEY]: " age_input
[ -n "$age_input" ] && AGE_KEY=$age_input

echo "== installing over SSH (nixos-anywhere)"
nix run github:nix-community/nixos-anywhere -- --flake "$REPO#homeserver" "root@$HOST"

echo "== waiting for the reboot"
sleep 20
for _ in $(seq 1 60); do
  if ssh -o BatchMode=yes -o ConnectTimeout=3 "$BOX_USER@$HOST" true 2>/dev/null; then break; fi
  sleep 5
done
ssh -o BatchMode=yes "$BOX_USER@$HOST" true

echo "== installing the sops age key"
ssh "$BOX_USER@$HOST" 'sudo install -d -m 700 /var/lib/sops-nix && sudo tee /var/lib/sops-nix/key.txt >/dev/null && sudo chmod 600 /var/lib/sops-nix/key.txt' < "$AGE_KEY"
ssh -o BatchMode=yes "$BOX_USER@$HOST" 'sudo systemctl restart sops-install-secrets'

echo "== bootstraping the cluster"
SEALED_KEY_FILE="$SEALED_KEY_FILE" HOST="$HOST" BOX_USER="$BOX_USER" REPO="$REPO" "$REPO/scripts/bootstrap.sh"

echo "== waiting for ArgoCD to sync"
sleep 30
kubectl -n argocd get applications || true

echo "== restoring data (k3s will be stopped)"
read -r -p "Press enter to restore /home and PV data from restic: "
ssh -o BatchMode=yes "$BOX_USER@$HOST" 'sudo systemctl stop k3s'
ssh -o BatchMode=yes "$BOX_USER@$HOST" 'sudo env RESTIC_REPOSITORY=/mnt/backup/restic RESTIC_PASSWORD_FILE=/run/secrets/restic-password restic restore latest --target / --include /home --include /var/lib/rancher/k3s/storage'
ssh -o BatchMode=yes "$BOX_USER@$HOST" 'sudo systemctl start k3s'

echo "restore complete. verify with: kubectl -n argocd get applications"

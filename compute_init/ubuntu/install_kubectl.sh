#!/bin/bash
set -euo pipefail

# Skip if kubectl already installed
if command -v kubectl >/dev/null 2>&1; then
  echo "kubectl already installed: $(kubectl version --client --short 2>/dev/null || kubectl version --client 2>/dev/null || true)"
  exit 0
fi

tmp_dir="$(mktemp -d)"
trap 'rm -rf "$tmp_dir"' EXIT

stable_ver="$(curl -fsSL https://dl.k8s.io/release/stable.txt)"
curl -fsSL -o "$tmp_dir/kubectl" "https://dl.k8s.io/release/${stable_ver}/bin/linux/amd64/kubectl"

sudo install -o root -g root -m 0755 "$tmp_dir/kubectl" /usr/local/bin/kubectl

kubectl version --client --short 2>/dev/null || kubectl version --client

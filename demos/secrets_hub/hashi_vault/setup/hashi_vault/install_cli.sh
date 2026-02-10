#!/usr/bin/env bash
set -euo pipefail

vault_version="${VAULT_VERSION:-1.17.3}"
arch="amd64"
os="linux"

tmp_dir="$(mktemp -d)"
trap 'rm -rf "$tmp_dir"' EXIT

cd "$tmp_dir"

echo "Installing Vault CLI v${vault_version}"

curl -fsSLO "https://releases.hashicorp.com/vault/${vault_version}/vault_${vault_version}_${os}_${arch}.zip"

unzip -q "vault_${vault_version}_${os}_${arch}.zip"

sudo install -o root -g root -m 0755 vault /usr/local/bin/vault

vault version

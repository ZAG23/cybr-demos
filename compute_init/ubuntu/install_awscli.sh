#!/bin/bash
set -euo pipefail

export DEBIAN_FRONTEND=noninteractive

log(){ echo "[INFO] $*"; }

# fail early if sudo would prompt
if ! sudo -n true 2>/dev/null; then
  echo "[ERROR] sudo requires a password (would prompt). Configure passwordless sudo or run as root." >&2
  exit 1
fi

# unzip
if ! command -v unzip >/dev/null 2>&1; then
  log "Installing unzip"
  sudo -n apt-get update -qq
  sudo -n apt-get install -y -qq unzip
else
  log "unzip already installed, skipping"
fi

# aws
if command -v aws >/dev/null 2>&1; then
  log "AWS CLI already installed: $(aws --version)"
  exit 0
fi

log "Installing AWS CLI v2"
tmp_dir="$(mktemp -d)"
trap 'rm -rf "$tmp_dir"' EXIT

curl -fsSL "https://awscli.amazonaws.com/awscli-exe-linux-x86_64.zip" -o "$tmp_dir/awscliv2.zip"
unzip -q "$tmp_dir/awscliv2.zip" -d "$tmp_dir"
sudo -n "$tmp_dir/aws/install"

log "Done: $(aws --version)"


#!/bin/bash
set -euo pipefail

# 1. Use existing CYBR_DEMOS_PATH or default to /opt/cybr-demos
export CYBR_DEMOS_PATH="${CYBR_DEMOS_PATH:-/opt/cybr-demos}"

# 2. Persist it only if it's not already in .profile to avoid duplicates
if ! grep -q "export CYBR_DEMOS_PATH=" "$HOME/.profile"; then
  echo "export CYBR_DEMOS_PATH=$CYBR_DEMOS_PATH" >> "$HOME/.profile"
fi

settings_dir="$HOME/.cybr-demos"

if [ -d "$settings_dir" ]; then
  echo "$settings_dir exists. Skipping compute setup"
  exit 0
fi

mkdir "$settings_dir"
chmod 700 "$settings_dir"

# Suppress debconf dialog
export DEBIAN_FRONTEND=noninteractive

# List of installation scripts
scripts=(
  "install_jq.sh"
  "install_tree.sh"
  "install_docker.sh"
  "install_terraform.sh"
  "install_awscli.sh"
  "install_kubectl.sh"
  "install_k9s.sh"
  "install_helm.sh"
)

# 3. Execute scripts using the variable
for script in "${scripts[@]}"; do
  sudo -i -u ubuntu bash "$CYBR_DEMOS_PATH/compute_init/ubuntu/$script"
done

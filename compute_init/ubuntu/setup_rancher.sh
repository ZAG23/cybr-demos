#!/bin/bash
set -euo pipefail

# ------------------------------
# Base paths
# ------------------------------
export cybr_demos_path="${CYBR_DEMOS_PATH:-/opt/cybr-demos}"

settings_dir="${cybr_demos_path}/settings"
log_file="${settings_dir}/init_log"
sentinel="${settings_dir}/.initialized"

# ------------------------------
# Idempotency check
# ------------------------------
if [[ -f "$sentinel" ]]; then
  echo "Already initialized ($sentinel exists). Skipping setup."
  exit 0
fi

# ------------------------------
# Init settings + logging
# ------------------------------
sudo mkdir -p "$settings_dir"
sudo chown ubuntu:ubuntu "$settings_dir"
sudo chmod 775 "$settings_dir"

sudo -u ubuntu touch "$log_file"
sudo chmod 664 "$log_file"

log() {
  echo "[$(date +'%Y-%m-%d %H:%M:%S')] $1" | tee -a "$log_file"
}

run_as_ubuntu() {
  # run arbitrary command as ubuntu, preserving HOME, no login shell side-effects
  sudo -u ubuntu -H -- "$@" >>"$log_file" 2>&1
}


export DEBIAN_FRONTEND=noninteractive

log "Starting compute + demo initialization..."

# ------------------------------
# Unified script list
# ------------------------------
scripts=(
  "${cybr_demos_path}/compute_init/ubuntu/install_jq.sh"
  "${cybr_demos_path}/compute_init/ubuntu/install_tree.sh"
  "${cybr_demos_path}/compute_init/ubuntu/install_awscli.sh"
  "${cybr_demos_path}/compute_init/ubuntu/install_kubectl.sh"
  "${cybr_demos_path}/compute_init/ubuntu/install_helm.sh"
  "${cybr_demos_path}/compute_init/ubuntu/install_rancher.sh"
  "${cybr_demos_path}/compute_init/ubuntu/install_k9s.sh"

  "${cybr_demos_path}/demos/secrets_manager/k8s/setup.sh"
)

# ------------------------------
# Execution loop
# ------------------------------
for script in "${scripts[@]}"; do
  log "Running: ${script}"
  if run_as_ubuntu bash "$script"; then
    log "SUCCESS: $(basename "$script")"
  else
    log "ERROR: $(basename "$script") failed. See ${log_file}"
    exit 1
  fi
done

# ------------------------------
# Mark initialized
# ------------------------------
sudo -u ubuntu touch "$sentinel"
log "Initialization complete."

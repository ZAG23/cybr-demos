#!/bin/bash
set -euo pipefail

# ------------------------------
# Base paths
# ------------------------------
export CYBR_DEMOS_PATH="${CYBR_DEMOS_PATH:-/opt/cybr-demos}"

settings_dir="${CYBR_DEMOS_PATH}/settings"
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
  local cmd="$1"
  sudo -i -u ubuntu bash -lc "$cmd" >>"$log_file" 2>&1
}

export DEBIAN_FRONTEND=noninteractive

log "Starting compute + demo initialization..."

# ------------------------------
# Unified script list
# ------------------------------
scripts=(
  "COMPUTE:${CYBR_DEMOS_PATH}/compute_init/ubuntu/install_jq.sh"
  "COMPUTE:${CYBR_DEMOS_PATH}/compute_init/ubuntu/install_tree.sh"
  "COMPUTE:${CYBR_DEMOS_PATH}/compute_init/ubuntu/install_awscli.sh"
  "COMPUTE:${CYBR_DEMOS_PATH}/compute_init/ubuntu/install_kubectl.sh"
  "COMPUTE:${CYBR_DEMOS_PATH}/compute_init/ubuntu/install_helm.sh"
  "COMPUTE:${CYBR_DEMOS_PATH}/compute_init/ubuntu/install_rancher.sh"
  "COMPUTE:${CYBR_DEMOS_PATH}/compute_init/ubuntu/install_k9s.sh"

  "DEMO:${CYBR_DEMOS_PATH}/demos/secrets_manager/k8s/setup.sh"
)

# ------------------------------
# Execution loop
# ------------------------------
for entry in "${scripts[@]}"; do
  phase="${entry%%:*}"
  script="${entry#*:}"

  log "[${phase}] Running: ${script}"

  if run_as_ubuntu "bash '$script'"; then
    log "[${phase}] SUCCESS: $(basename "$script")"
  else
    log "[${phase}] ERROR: $(basename "$script") failed. See ${log_file}"
    exit 1
  fi
done

# ------------------------------
# Mark initialized
# ------------------------------
sudo -u ubuntu touch "$sentinel"
log "Initialization complete."

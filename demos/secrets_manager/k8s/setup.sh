#!/bin/bash
set -euo pipefail

demo_path="$CYBR_DEMOS_PATH/demos/secrets_manager/k8s"

# Init K8s metadata
cd "$demo_path/setup/k8s"
./init_rancher.sh

# Setup Vault
cd "$demo_path/setup/vault"
./setup.sh

# Setup Secrets Manager
cd "$demo_path/setup/sm"
./setup.sh

# Setup K8s
cd "$demo_path/setup/k8s"
./setup.sh

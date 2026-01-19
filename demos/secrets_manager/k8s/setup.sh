#!/bin/bash
set -euo pipefail

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

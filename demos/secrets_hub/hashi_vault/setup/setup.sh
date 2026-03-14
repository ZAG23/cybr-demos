#!/bin/bash
set -euo pipefail

demo_path="$CYBR_DEMOS_PATH/demos/secrets_hub/hashi_vault"
# Set environment variables using .env file
# -a means that every bash variable would become an environment variable
# Using ‘+’ rather than ‘-’ causes the option to be turned off
set -a
source "$demo_path/setup/vars.env"
set +a

export sm_fqdn="$SM_FQDN"
export sm_namespace="$NAMESPACE"

# Setup Vault
cd "$demo_path/setup/cert_manager"
./setup.sh

# Setup Secrets Manager
cd "$demo_path/setup/hashi_vault"
./setup.sh

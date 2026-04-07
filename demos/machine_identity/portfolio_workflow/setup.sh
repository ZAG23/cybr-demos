#!/bin/bash
set -euo pipefail

demo_path="$CYBR_DEMOS_PATH/demos/machine_identity/portfolio_workflow"

set -a
source "$CYBR_DEMOS_PATH/demos/setup_env.sh"
source "$demo_path/setup/vars.env"
set +a

printf "\n[INFO] Machine Identity Portfolio - Setup\n"
printf "[INFO] USECASE_ID: %s\n" "$USECASE_ID"

# Stage 1: Vault (Safe + Accounts)
printf "\n[INFO] Stage 1: Vault Setup\n"
cd "$demo_path/setup/vault"
./setup.sh

# Stage 2: Secrets Manager (Conjur Policy + Workload Identity)
printf "\n[INFO] Stage 2: Secrets Manager Setup\n"
cd "$demo_path/setup/sm"
./setup.sh

# Stage 3: Secrets Hub (Target Store + Sync Policy)
printf "\n[INFO] Stage 3: Secrets Hub Setup\n"
cd "$demo_path/setup/secrets_hub"
./setup.sh

# Stage 4: Secure Infrastructure Access
printf "\n[INFO] Stage 4: SIA Setup\n"
cd "$demo_path/setup/sia"
./setup.sh

# Stage 5: VCert Python SDK (Certificate Lifecycle)
printf "\n[INFO] Stage 5: VCert SDK Setup\n"
cd "$demo_path/setup/vcert"
./setup.sh

# Stage 6: cert-manager + CyberArk Issuer (K8s Certificate Automation)
printf "\n[INFO] Stage 6: cert-manager Setup\n"
cd "$demo_path/setup/cert_manager"
./setup.sh

# Stage 7: Secure AI Agents (Agent Identity Lifecycle)
printf "\n[INFO] Stage 7: Secure AI Agents Setup\n"
cd "$demo_path/setup/sai"
./setup.sh

printf "\n[INFO] Setup complete. Run demo.sh to walk through the portfolio.\n"

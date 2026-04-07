#!/bin/bash
set -euo pipefail

source "$CYBR_DEMOS_PATH/demos/utility/ubuntu/identity_functions.sh"
source "$CYBR_DEMOS_PATH/demos/utility/ubuntu/conjur_functions.sh"

printf "\n[INFO] Secrets Manager: Authenticating\n"
identity_token=$(get_identity_token "$TENANT_ID" "$CLIENT_ID" "$CLIENT_SECRET")
conjur_token=$(get_conjur_token "$TENANT_SUBDOMAIN" "$identity_token")

printf "[INFO] Secrets Manager: Waiting for Vault Synchronizer\n"
wait_for_synchronizer "$TENANT_SUBDOMAIN" "$conjur_token" "$SAFE_NAME"
printf " synced\n"

printf "[INFO] Secrets Manager: Applying workload identity policy\n"

workload_policy="- !policy
  id: $SM_SERVICE_NAME
  body:
    - !host
      id: demo-workload
      annotations:
        authn/api-key: true

    - !group consumers

    - !grant
      role: !group consumers
      member: !host demo-workload

    - !grant
      role: !group /data/vault/$SAFE_NAME/delegation/consumers
      member: !group consumers"

apply_conjur_policy "$TENANT_SUBDOMAIN" "$conjur_token" "data" "$workload_policy"

printf "\n[INFO] Secrets Manager: Rotating workload API key\n"
api_key=$(rotate_workload_api_key "$TENANT_SUBDOMAIN" "$conjur_token" "data/$SM_SERVICE_NAME/demo-workload")

printf "[INFO] Secrets Manager: Workload API key: %s\n" "${api_key:0:8}..."
printf "[INFO] Secrets Manager: Setup complete\n"

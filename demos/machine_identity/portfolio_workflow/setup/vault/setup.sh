#!/bin/bash
set -euo pipefail

source "$CYBR_DEMOS_PATH/demos/utility/ubuntu/identity_functions.sh"
source "$CYBR_DEMOS_PATH/demos/utility/ubuntu/privilege_functions.sh"

printf "\n[INFO] Vault: Authenticating to ISPSS\n"
identity_token=$(get_identity_token "$TENANT_ID" "$CLIENT_ID" "$CLIENT_SECRET")

printf "[INFO] Vault: Creating safe '%s'\n" "$SAFE_NAME"
create_safe "$TENANT_SUBDOMAIN" "$identity_token" "$SAFE_NAME"

printf "\n[INFO] Vault: Adding Secrets Hub and Conjur Sync roles\n"
add_safe_read_member "$TENANT_SUBDOMAIN" "$identity_token" "$SAFE_NAME" "Secrets Hub"
add_safe_read_member "$TENANT_SUBDOMAIN" "$identity_token" "$SAFE_NAME" "Conjur Sync"

printf "\n[INFO] Vault: Creating demo accounts\n"

# Database host account
curl --silent --location "https://$TENANT_SUBDOMAIN.privilegecloud.cyberark.cloud/PasswordVault/API/Accounts/" \
  --header "Authorization: Bearer $identity_token" \
  --header 'Content-Type: application/json' \
  --data "{
    \"name\": \"account-db-host\",
    \"address\": \"db-prod.internal.example.com\",
    \"userName\": \"db-admin\",
    \"platformId\": \"MySQL\",
    \"safeName\": \"$SAFE_NAME\",
    \"secretType\": \"password\",
    \"secret\": \"ProdDbP@ss2024!\",
    \"secretManagement\": {
      \"automaticManagementEnabled\": false,
      \"manualManagementReason\": \"Demo account\"
    }
  }"

# Database user account
curl --silent --location "https://$TENANT_SUBDOMAIN.privilegecloud.cyberark.cloud/PasswordVault/API/Accounts/" \
  --header "Authorization: Bearer $identity_token" \
  --header 'Content-Type: application/json' \
  --data "{
    \"name\": \"account-db-user\",
    \"address\": \"db-prod.internal.example.com\",
    \"userName\": \"app-svc-account\",
    \"platformId\": \"MySQL\",
    \"safeName\": \"$SAFE_NAME\",
    \"secretType\": \"password\",
    \"secret\": \"AppSvcP@ss2024!\",
    \"secretManagement\": {
      \"automaticManagementEnabled\": false,
      \"manualManagementReason\": \"Demo account\"
    }
  }"

# API key account
curl --silent --location "https://$TENANT_SUBDOMAIN.privilegecloud.cyberark.cloud/PasswordVault/API/Accounts/" \
  --header "Authorization: Bearer $identity_token" \
  --header 'Content-Type: application/json' \
  --data "{
    \"name\": \"account-api-key\",
    \"address\": \"api.partner.example.com\",
    \"userName\": \"svc-api-consumer\",
    \"platformId\": \"UnixSSH\",
    \"safeName\": \"$SAFE_NAME\",
    \"secretType\": \"password\",
    \"secret\": \"ak_live_7f3d92a1b8e64c0d9\",
    \"secretManagement\": {
      \"automaticManagementEnabled\": false,
      \"manualManagementReason\": \"Demo account\"
    }
  }"

printf "\n[INFO] Vault: Setup complete\n"

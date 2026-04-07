#!/bin/bash
set -euo pipefail

source "$CYBR_DEMOS_PATH/demos/utility/ubuntu/identity_functions.sh"

printf "\n[INFO] Secrets Hub: Authenticating\n"
identity_token=$(get_identity_token "$TENANT_ID" "$CLIENT_ID" "$CLIENT_SECRET")

if [ -z "$SH_AWS_ACCOUNT_ID" ]; then
  printf "[WARN] Secrets Hub: SH_AWS_ACCOUNT_ID not set in vars.env - skipping AWS target store creation\n"
  printf "[INFO] Secrets Hub: Set SH_AWS_ACCOUNT_ID, SH_AWS_REGION, SH_AWS_ROLE_NAME to enable\n"
  exit 0
fi

printf "[INFO] Secrets Hub: Creating AWS Secrets Manager target store\n"
store_response=$(curl --silent --location \
  "https://$TENANT_SUBDOMAIN.secretshub.cyberark.cloud/api/secret-stores" \
  --header "Authorization: Bearer $identity_token" \
  --header 'Content-Type: application/json' \
  --data "{
    \"type\": \"AWS_ASM\",
    \"name\": \"$USECASE_ID-aws-target\",
    \"description\": \"Machine Identity demo - AWS target store\",
    \"data\": {
      \"accountId\": \"$SH_AWS_ACCOUNT_ID\",
      \"regionId\": \"$SH_AWS_REGION\",
      \"roleName\": \"$SH_AWS_ROLE_NAME\"
    }
  }")

target_store_id=$(printf '%s' "$store_response" | jq -r '.id // empty')

if [ -z "$target_store_id" ]; then
  printf "[ERROR] Secrets Hub: Failed to create target store\n%s\n" "$store_response"
  exit 1
fi
printf "[INFO] Secrets Hub: Target store created (id: %s)\n" "$target_store_id"

# Get the PAM source store ID (Privilege Cloud is auto-registered)
printf "[INFO] Secrets Hub: Looking up PAM source store\n"
source_stores=$(curl --silent --location \
  "https://$TENANT_SUBDOMAIN.secretshub.cyberark.cloud/api/secret-stores" \
  --header "Authorization: Bearer $identity_token")

source_store_id=$(printf '%s' "$source_stores" | jq -r '[.[] | select(.type == "PAM")][0].id // empty')

if [ -z "$source_store_id" ]; then
  printf "[ERROR] Secrets Hub: No PAM source store found\n"
  exit 1
fi
printf "[INFO] Secrets Hub: PAM source store (id: %s)\n" "$source_store_id"

printf "[INFO] Secrets Hub: Creating sync policy '%s'\n" "$SH_POLICY_NAME"
curl --silent --location \
  "https://$TENANT_SUBDOMAIN.secretshub.cyberark.cloud/api/policies" \
  --header "Authorization: Bearer $identity_token" \
  --header 'Content-Type: application/json' \
  --data "{
    \"name\": \"$SH_POLICY_NAME\",
    \"description\": \"Sync $SAFE_NAME secrets to AWS Secrets Manager\",
    \"source\": {
      \"id\": \"$source_store_id\"
    },
    \"target\": {
      \"id\": \"$target_store_id\"
    },
    \"filter\": {
      \"type\": \"PAM_SAFE\",
      \"data\": {
        \"safeName\": \"$SAFE_NAME\"
      }
    }
  }"

printf "\n[INFO] Secrets Hub: Setup complete\n"

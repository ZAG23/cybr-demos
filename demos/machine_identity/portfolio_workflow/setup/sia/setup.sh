#!/bin/bash
set -euo pipefail

source "$CYBR_DEMOS_PATH/demos/utility/ubuntu/identity_functions.sh"

printf "\n[INFO] SIA: Authenticating\n"
identity_token=$(get_identity_token "$TENANT_ID" "$CLIENT_ID" "$CLIENT_SECRET")

if [ -z "$SIA_TARGET_HOST" ]; then
  printf "[WARN] SIA: SIA_TARGET_HOST not set in vars.env - skipping SIA setup\n"
  printf "[INFO] SIA: Set SIA_TARGET_HOST and SIA_TARGET_USER to enable\n"
  exit 0
fi

printf "[INFO] SIA: Creating strong account for target host '%s'\n" "$SIA_TARGET_HOST"

curl --silent --location \
  "https://$TENANT_SUBDOMAIN.dpa.cyberark.cloud/api/public/connections/targets" \
  --header "Authorization: Bearer $identity_token" \
  --header 'Content-Type: application/json' \
  --data "{
    \"name\": \"$USECASE_ID-target\",
    \"address\": \"$SIA_TARGET_HOST\",
    \"platform_type\": \"Unix\",
    \"protocols\": [\"SSH\"],
    \"credentials\": {
      \"type\": \"strong_account\",
      \"username\": \"$SIA_TARGET_USER\"
    }
  }"

printf "\n[INFO] SIA: Setup complete\n"

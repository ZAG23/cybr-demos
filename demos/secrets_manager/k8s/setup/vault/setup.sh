#!/bin/bash
# shellcheck disable=SC2059
set -euo pipefail

demo_path="$CYBR_DEMOS_PATH/demos/secret_manager/k8s"
# Set environment variables using .env file
# -a means that every bash variable would become an environment variable
# Using ‘+’ rather than ‘-’ causes the option to be turned off
set -a
source "$CYBR_DEMOS_PATH/demos/setup_env.sh"
source "$demo_path/setup/vars.env"
set +a

printf "\nSetting local vars from Env"
isp_id=$TENANT_ID
isp_subdomain=$TENANT_SUBDOMAIN
client_id=$CLIENT_ID
client_secret=$CLIENT_SECRET
safe_name=$SAFE_NAME

identity_token=$(get_identity_token "$isp_id" "$client_id" "$client_secret")
printf "\n\nidentity_token: \n$identity_token\n"

create_safe "$isp_subdomain" "$identity_token" "$safe_name"
add_safe_admin_role "$isp_subdomain" "$identity_token" "$safe_name" "Privilege Cloud Administrators"
add_safe_read_member "$isp_subdomain" "$identity_token" "$safe_name" "Conjur Sync"

create_account_ssh_user_1 "$isp_subdomain" "$identity_token" "$safe_name"

conjur_token=$(get_conjur_token "$isp_subdomain" "$identity_token")
printf "\n\nconjur_token: \n$conjur_token\n"
printf "Waiting for synchronizer (*/$safe_name/delegation/consumers)\n"
wait_for_synchronizer "$isp_subdomain" "$conjur_token" "$safe_name"

#!/bin/bash
# shellcheck disable=SC2005
# shellcheck disable=SC2059
set -euo pipefail

demo_path="$CYBR_DEMOS_PATH/demos/conjur_cloud/k8s"
# Set environment variables using .env file
# -a means that every bash variable would become an environment variable
# Using ‘+’ rather than ‘-’ causes the option to be turned off
set -a
source "$CYBR_DEMOS_PATH/demos/setup_env.sh"
source "$demo_path/setup/vars.env"
set +a

printf "\n\nSetting local vars from Env\n"
isp_id=$TENANT_ID
isp_subdomain=$TENANT_SUBDOMAIN
client_id=$CLIENT_ID
client_secret=$CLIENT_SECRET
jwt_claim_identity=$JWT_CLAIM_IDENTITY
sm_service_name=$SM_SERVICE_NAME

auth_jwks_uri_id="conjur/authn-jwt/$sm_service_name/jwks-uri"
auth_jwks_uri_value="https://token.actions.githubusercontent.com/.well-known/jwks"

auth_issuer_id="conjur/authn-jwt/$sm_service_name/issuer"
auth_issuer_value="https://token.actions.githubusercontent.com"

auth_token_app_property_id="conjur/authn-jwt/$sm_service_name/token-app-property"
auth_token_app_property_value="repository"

auth_identity_path_id="conjur/authn-jwt/$sm_service_name/identity-path"
auth_identity_path_value="data/poc-workloads"

printf "\n\nplatform_auth $isp_id $client_id $client_secret\n"
identity_token=$(get_identity_token "$isp_id" "$client_id" "$client_secret")
printf "\n\nidentity_token: \n$identity_token\n"

printf "\n\nconjur_isp_auth $isp_subdomain identity_token\n"
conjur_token=$(get_conjur_token "$isp_subdomain" "$identity_token")
printf "\n\nconjur_token: \n$conjur_token\n"

# Setup Auth Service
printf "\n\napply_conjur_policies $isp_subdomain conjur_token branch policy\n"

apply_conjur_policy "$isp_subdomain" "$conjur_token" "data" "$(cat poc-workloads.yaml)"
apply_conjur_policy "$isp_subdomain" "$conjur_token" "conjur/authn-jwt" "$(cat jwt_service_poc_k8s.yaml)"

printf "\n\napply_conjur_secret $isp_subdomain conjur_token id value\n"

apply_conjur_secret "$isp_subdomain" "$conjur_token" "$auth_jwks_uri_id" "$auth_jwks_uri_value"
apply_conjur_secret "$isp_subdomain" "$conjur_token" "$auth_token_app_property_id" "$auth_token_app_property_value"
apply_conjur_secret "$isp_subdomain" "$conjur_token" "$auth_identity_path_id" "$auth_identity_path_value"
apply_conjur_secret "$isp_subdomain" "$conjur_token" "$authissuer_id" "$auth_issuer_value"

printf "\n\nactivate_conjur_service $isp_subdomain conjur_token service_id\n"
activate_conjur_service "$isp_subdomain" "$conjur_token" "authn-jwt/$service_id"

# Setup Workloads

printf "\n\nresolve_template workload1.tmpl.yaml workload1.yaml\n"
resolve_template "workload1.tmpl.yaml" "workload1.yaml"

printf "\n\napply_conjur_policies $isp_subdomain conjur_token branch policy\n"

apply_conjur_policy "$isp_subdomain" "$conjur_token" "data" "$(cat workload1.yaml)"

printf "\n"

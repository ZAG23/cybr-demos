#!/bin/bash
# shellcheck disable=SC2005
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

printf "\n\nSetting local vars from Env\n"
isp_id=$TENANT_ID
isp_subdomain=$TENANT_SUBDOMAIN
client_id=$CLIENT_ID
client_secret=$CLIENT_SECRET
jwt_claim_identity=$JWT_CLAIM_IDENTITY
sm_service_name=$SM_SERVICE_NAME

echo "isp_id=${isp_id:-<unset>}"
echo "isp_subdomain=${isp_subdomain:-<unset>}"
echo "client_id=${client_id:-<unset>}"''
echo "client_secret=${client_secret:-<unset>}"
echo "jwt_claim_identity=${jwt_claim_identity:-<unset>}"
echo "sm_service_name=${sm_service_name:-<unset>}"

# Setup Auth Service
printf "\n\napply conjur policies\n"

printf '\n\nplatform_auth %s %s %s\n' "${isp_id:-}" "${client_id:-}" "${client_secret:-}"
identity_token=$(get_identity_token "$isp_id" "$client_id" "$client_secret")
printf "\n\nidentity_token: \n$identity_token\n"

printf "\n\nconjur_isp_auth $isp_subdomain identity_token\n"
conjur_token=$(get_conjur_token "$isp_subdomain" "$identity_token")
printf "\n\nconjur_token: \n$conjur_token\n"

apply_conjur_policy "$isp_subdomain" "$conjur_token" "data" "$(cat poc-workloads.yaml)"

case "${K8S_TYPE,,}" in
  rancher|ocp)
    validation_type="public-keys"
    validation_value="{"type":"jwks","value":{ $K8S_PUBLIC_KEYS }"
    apply_conjur_policy "$isp_subdomain" "$conjur_token" "conjur/authn-jwt" "$(cat authenticator_public_key.yaml)"

    ;;
  eks|k8s)
    validation_type="jwks"
    validation_value="K8S_JWKS_URI"
    ;;
  *)
    echo "ERROR: Unsupported K8S_TYPE=$K8S_TYPE" >&2
    apply_conjur_policy "$isp_subdomain" "$conjur_token" "conjur/authn-jwt" "$(cat authenticator_jwks.yaml)"
    exit 1
    ;;
esac

# Configure Auth Service
auth_jwks_validation="conjur/authn-jwt/$sm_service_name/$validation_type"
auth_jwks_validation_value="$validation_value"

auth_issuer_id="conjur/authn-jwt/$sm_service_name/issuer"
auth_issuer_value="https://kubernetes.default.svc"

auth_token_app_property_id="conjur/authn-jwt/$sm_service_name/token-app-property"
auth_token_app_property_value="sub"

auth_identity_path_id="conjur/authn-jwt/$sm_service_name/identity-path"
auth_identity_path_value="data/poc-workloads"

printf "\n\nConfigure Authenticator: $sm_service_name\n"
apply_conjur_secret "$isp_subdomain" "$conjur_token" "$auth_jwks_validation" "$auth_jwks_validation_value"
apply_conjur_secret "$isp_subdomain" "$conjur_token" "$auth_token_app_property_id" "$auth_token_app_property_value"
apply_conjur_secret "$isp_subdomain" "$conjur_token" "$auth_identity_path_id" "$auth_identity_path_value"
apply_conjur_secret "$isp_subdomain" "$conjur_token" "$auth_issuer_id" "$auth_issuer_value"

printf "\n\nactivate_conjur_service $isp_subdomain conjur_token service_id\n"
activate_conjur_service "$isp_subdomain" "$conjur_token" "authn-jwt/$sm_service_name"

# Setup Workloads

printf "\n\nresolve workload templates \n"
resolve_template "workload.tmpl.yaml" "workload.yaml"
resolve_template "add_workload_to_safe.tmpl.yaml" "add_workload_to_safe.yaml"
resolve_template "add_workload_to_authenticator.tmpl.yaml" "add_workload_to_authenticator.yaml"

printf "\n\napply_conjur_policies $isp_subdomain conjur_token branch policy\n"

apply_conjur_policy "$isp_subdomain" "$conjur_token" "data" "$(cat workload.yaml)"
apply_conjur_policy "$isp_subdomain" "$conjur_token" "data" "$(cat add_workload_to_safe.yaml)"
apply_conjur_policy "$isp_subdomain" "$conjur_token" "conjur/authn-jwt" "$(cat add_workload_to_authenticator.yaml)"
printf "\n"

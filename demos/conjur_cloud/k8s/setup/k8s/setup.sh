#!/bin/bash
set -euo pipefail

# ------------------------------------------------------------------------------
# Environment Setup
# ------------------------------------------------------------------------------

demo_path="$CYBR_DEMOS_PATH/demos/conjur_cloud/k8s"
# Set environment variables using .env file
# -a means that every bash variable would become an environment variable
# Using ‘+’ rather than ‘-’ causes the option to be turned off
set -a
source "$demo_path/setup/vars.env"
set +a

sm_fqdn="$TENANT_SUBDOMAIN.secretsmgr.cyberark.cloud"
sm_service_name="$SM_SERVICE_NAME"

sm_secret_1_id="$SM_SECRET_1_ID"
sm_secret_1_name="$SM_SECRET_1_NAME"
sm_secret_2_id="$SM_SECRET_2_ID"
sm_secret_2_name="$SM_SECRET_2_NAME"

echo "sm_fqdn=${sm_fqdn:-<unset>}"
echo "sm_service_name=${sm_service_name:-<unset>}"
echo "sm_secret_1_id=${sm_secret_1_id:-<unset>}"
echo "sm_secret_1_name=${sm_secret_1_name:-<unset>}"
echo "sm_secret_2_id=${sm_secret_2_id:-<unset>}"
echo "sm_secret_2_name=${sm_secret_2_name:-<unset>}"

[ -n "${sm_fqdn:-}" ] || exit 1
[ -n "${sm_service_name:-}" ] || exit 1
[ -n "${sm_secret_1_id:-}" ] || exit 1
[ -n "${sm_secret_1_name:-}" ] || exit 1
[ -n "${sm_secret_2_id:-}" ] || exit 1
[ -n "${sm_secret_2_name:-}" ] || exit 1

# ------------------------------------------------------------------------------
# Install External Secrets Operator
# ------------------------------------------------------------------------------

# Add/update repo
helm repo add external-secrets https://charts.external-secrets.io
helm repo update

# Install/upgrade External Secrets Operator (ESO) + its CRDs
helm upgrade --install external-secrets external-secrets/external-secrets \
  --namespace external-secrets \
  --create-namespace \
  --set installCRDs=true \
  --timeout 10m \
  --debug \
  --wait

# Verify CRDs exist
kubectl get crd | grep -Ei 'externalsecrets\.external-secrets\.io|secretstores\.external-secrets\.io|clustersecretstores\.external-secrets\.io' \
  || echo "Missing ESO CRDs"

# Show served versions (useful when debugging mismatches)
kubectl get crd \
  externalsecrets.external-secrets.io \
  secretstores.external-secrets.io \
  clustersecretstores.external-secrets.io \
  -o 'custom-columns=NAME:.metadata.name,SERVED:.spec.versions[?(@.served==true)].name'


# Verify pods are running
kubectl -n external-secrets get pods -o wide

# Quick API visibility check (optional)
kubectl api-resources | grep -Ei 'externalsecret|secretstore|clustersecretstore' \
  || echo "ESO API resources not visible yet"

# ------------------------------------------------------------------------------
# Install Secrets Manager SaaS Use Cases
# ------------------------------------------------------------------------------

openssl s_client -connect "$sm_fqdn:443" -servername "$sm_fqdn" </dev/null 2>/dev/null \
| sed -ne '/-BEGIN CERTIFICATE-/,/-END CERTIFICATE-/p' \
| openssl x509 -inform pem -text > sm.pem

# Helm install Release names does not allow '_' use '-'
helm upgrade --install poc-sm \
     $demo_path/setup/k8s/charts/poc-sm \
     --namespace default \
     --set namespace=$sm_service_name \
     --set sm_fqdn="$sm_fqdn" \
     --set sm_cert_b64="$(cat sm.pem | base64 -w0 )" \
     --set sm_authn_id=$sm_service_name \
     --set sm_app_service_account="poc-service-account" \
     --set sm_secret_1_id="$sm_secret_1_id" \
     --set sm_secret_1_name="$sm_secret_1_name" \
     --set sm_secret_2_id="$sm_secret_2_id" \
     --set sm_secret_2_name="$sm_secret_2_name" \
     --debug

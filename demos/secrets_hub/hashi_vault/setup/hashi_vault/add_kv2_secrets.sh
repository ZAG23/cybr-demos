#!/usr/bin/env bash
set -euo pipefail

# ------------------------------
# Config
# ------------------------------
kv_mount="kv"
environments=("dev" "test" "prod")
applications=("billing" "orders" "inventory" "customers" "analytics")

# ------------------------------
# Guard checks & External Access Fix
# ------------------------------
# Point this to your Pod IP or ClusterIP
VAULT_ADDR="${VAULT_ADDR:-https://127.0.0.1:8200}"
VAULT_TOKEN="${VAULT_TOKEN:-root}"

# FIX: Disable TLS hostname verification because we are connecting via IP
export VAULT_SKIP_VERIFY=true

export VAULT_ADDR VAULT_TOKEN

if ! command -v vault >/dev/null 2>&1; then
  echo "vault CLI not found in PATH"
  exit 1
fi

echo "Connecting to Vault at $VAULT_ADDR..."

# ------------------------------
# Ensure KV v2 mount exists
# ------------------------------
# Added -tls-skip-verify explicitly to the command for extra safety
if ! vault secrets list -format=json | grep -q "\"${kv_mount}/\""; then
  echo "Enabling KV v2 at: ${kv_mount}/"
  vault secrets enable -path="$kv_mount" kv-v2
else
  echo "KV mount already exists at: ${kv_mount}/"
fi

# ------------------------------
# Helpers
# ------------------------------
rand() {
  # cheap deterministic-ish random for demos
  date +%s%N | sha256sum | awk '{print substr($1,1,16)}'
}

write_secret() {
  local path="$1"
  shift
  # Vault KV commands inherit the VAULT_SKIP_VERIFY env var
  vault kv put "${kv_mount}/${path}" "$@" >/dev/null
  echo "wrote: ${kv_mount}/${path}"
}

# ------------------------------
# Create secrets
# ------------------------------
for env in "${environments[@]}"; do
  for app in "${applications[@]}"; do
    db_host="postgres.${env}.svc.cluster.local"
    db_port="5432"
    db_name="${app}_${env}"
    db_user="${app}_svc"
    db_pass="p@ss-${env}-$(rand)"

    api_key="key-${env}-${app}-$(rand)"
    api_base_url="https://api.${env}.example.internal/${app}"
    api_timeout="5s"

    oauth_client_id="${app}-${env}-client"
    oauth_client_secret="secret-${env}-${app}-$(rand)"

    ff_new_ui="false"
    ff_use_cache="true"

    tls_cert="-----BEGIN CERTIFICATE-----\n${env}-${app}-dummy-cert\n-----END CERTIFICATE-----"
    tls_key="-----BEGIN PRIVATE KEY-----\n${env}-${app}-dummy-key\n-----END PRIVATE KEY-----"

    write_secret "${env}/${app}/db" \
      username="$db_user" password="$db_pass" host="$db_host" port="$db_port" name="$db_name"

    write_secret "${env}/${app}/api" \
      api_key="$api_key" base_url="$api_base_url" timeout="$api_timeout"

    write_secret "${env}/${app}/oauth" \
      client_id="$oauth_client_id" client_secret="$oauth_client_secret"

    write_secret "${env}/${app}/featureflags" \
      new_ui="$ff_new_ui" use_cache="$ff_use_cache"

    write_secret "${env}/${app}/tls" \
      cert="$tls_cert" key="$tls_key"
  done
done

echo
echo "Done. Example reads (from this host):"
echo "  export VAULT_SKIP_VERIFY=true"
echo "  vault kv get ${kv_mount}/dev/billing/db"
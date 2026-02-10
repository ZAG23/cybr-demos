#!/usr/bin/env bash
set -euo pipefail

# ANSI bold
BOLD="\033[1m"
RESET="\033[0m"

## --- Config (env or default) ---
export VAULT_ADDR="${VAULT_ADDR:-http://127.0.0.1:8200}"
export VAULT_TOKEN="${VAULT_TOKEN:-root}"

export ROLE_NAME="${ROLE_NAME:-poc-sh-role}"
export POLICY_NAME="${POLICY_NAME:-SecretsHubHashiVaultRolePolicy}"

export JWT_PATH="${JWT_PATH:-jwt}"
export MOUNT_PATH="${MOUNT_PATH:-kv}"
export OIDC_DISCOVERY_URL="${OIDC_DISCOVERY_URL:-https://kubernetes.default.svc}"

export VAULT_SKIP_VERIFY=true

## --- Config (env or default) ---
#ROLE_NAME="${ROLE_NAME:-demo-role}"
#JWT_PATH="${JWT_PATH:-auth/jwt}"
#MOUNT_PATH="${MOUNT_PATH:-kv}"
#OIDC_DISCOVERY_URL="${OIDC_DISCOVERY_URL:-https://kubernetes.default.svc}"
#
#export ROLE_NAME JWT_PATH MOUNT_PATH OIDC_DISCOVERY_URL


# --- Validate env vars ---
if [[ -z "${VAULT_ADDR:-}" ]]; then
  echo -e "${BOLD}Error:${RESET} VAULT_ADDR environment variable is not set."
  exit 1
fi
if [[ -z "${VAULT_TOKEN:-}" ]]; then
  echo -e "${BOLD}Error:${RESET} VAULT_TOKEN environment variable is not set."
  exit 1
fi

## --- Get user inputs ---
#read -rp "$(echo -e "${BOLD}Enter role name:${RESET} ")" ROLE_NAME
#read -rp "$(echo -e "${BOLD}Enter JWT path:${RESET} ")" JWT_PATH
#read -rp "$(echo -e "${BOLD}Enter engine mount path:${RESET} ")" MOUNT_PATH
#read -rp "$(echo -e "${BOLD}Enter OIDC discovery URL:${RESET} ")" OIDC_DISCOVERY_URL

#POLICY_NAME="SecretsHubHashiVaultRolePolicy"
AUDIENCE="SecretsHub"
SUBJECT="SECRETS_HUB_HASHI_IDENTITY_APPLICATION_USER"
TOKEN_TTL=900

echo ""
echo -e "${BOLD}Vault address:${RESET} $VAULT_ADDR"
echo -e "${BOLD}Mount path:${RESET} $MOUNT_PATH"
echo -e "${BOLD}Role name:${RESET} $ROLE_NAME"
echo -e "${BOLD}OIDC discovery URL:${RESET} $OIDC_DISCOVERY_URL"
echo ""

# --- Create or override policy (safe loop) ---
while true; do
  if vault policy read "$POLICY_NAME" &>/dev/null; then
    echo -e "${BOLD}Policy '${POLICY_NAME}' already exists.${RESET}"
    read -rp "$(echo -e "Press Enter to override it, or type a new name to create instead: ")" NEW_POLICY
    if [[ -n "$NEW_POLICY" ]]; then
      POLICY_NAME="$NEW_POLICY"
      continue  # re-check in case new name also exists
    fi
  fi

  echo -e "${BOLD}Creating/overriding policy $POLICY_NAME...${RESET}"
  vault policy write "$POLICY_NAME" - <<EOF
path "${MOUNT_PATH}/data/*" {
  capabilities = ["read", "list", "create", "update", "patch", "delete"]
}
path "${MOUNT_PATH}/metadata/*" {
  capabilities = ["read", "list", "create", "update", "patch", "delete"]
}
path "${MOUNT_PATH}/delete/*" {
  capabilities = ["create", "update"]
}
path "${MOUNT_PATH}/undelete/*" {
  capabilities = ["create", "update"]
}
path "${MOUNT_PATH}/destroy/*" {
  capabilities = ["create", "update"]
}
path "${MOUNT_PATH}/subkeys/*" {
  capabilities = ["read"]
}
path "sys/mounts/${MOUNT_PATH}/*" {
  capabilities = ["read"]
}
EOF
  echo -e "✅ ${BOLD}Policy ready.${RESET}"
  break
done

# --- Enable JWT auth backend ---
if ! vault auth list | grep -q "^${JWT_PATH}/"; then
  echo -e "${BOLD}Enabling JWT auth backend at path $JWT_PATH...${RESET}"
  vault auth enable -path="$JWT_PATH" jwt
  echo -e "✅ ${BOLD}JWT auth backend enabled.${RESET}"
else
  echo -e "${BOLD}JWT auth backend already enabled at path $JWT_PATH, skipping enable.${RESET}"
fi

# --- Configure JWT auth backend ---
echo -e "${BOLD}Configuring JWT auth backend...${RESET}"
vault write auth/"$JWT_PATH"/config -<<EOF
{
  "oidc_discovery_url": "$OIDC_DISCOVERY_URL",
  "bound_issuer": "$OIDC_DISCOVERY_URL",
  "insecure_tls_skip_verify": true
}
EOF
echo -e "✅ ${BOLD}JWT auth backend configured.${RESET}"

# --- Create or override role (safe loop) ---
while true; do
  if vault read -format=json "auth/${JWT_PATH}/role/${ROLE_NAME}" &>/dev/null; then
    echo -e "${BOLD}Role '${ROLE_NAME}' already exists.${RESET}"
    read -rp "$(echo -e "Press Enter to override it, or type a new name to create instead: ")" NEW_ROLE
    if [[ -n "$NEW_ROLE" ]]; then
      ROLE_NAME="$NEW_ROLE"
      continue  # re-check in case new role also exists
    fi
  fi

  echo -e "${BOLD}Creating/overriding role $ROLE_NAME...${RESET}"
  vault write auth/"$JWT_PATH"/role/"$ROLE_NAME" -<<EOF
{
  "role_type": "jwt",
  "user_claim": "sub",
  "bound_audiences": ["$AUDIENCE"],
  "token_policies": ["$POLICY_NAME"],
  "token_ttl": $TOKEN_TTL,
  "bound_claims": {
    "sub": ["$SUBJECT"]
  }
}
EOF
  echo -e "✅ ${BOLD}Role ready.${RESET}"
  break
done

# --- Summary ---
echo
echo -e "${BOLD}Setup complete!${RESET}"
echo -e "${BOLD}Vault address:${RESET} $VAULT_ADDR"
echo -e "${BOLD}Mount path:${RESET} $MOUNT_PATH"
echo -e "${BOLD}Policy name:${RESET} $POLICY_NAME"
echo -e "${BOLD}Role name:${RESET} $ROLE_NAME"
echo -e "${BOLD}Authentication path:${RESET} $JWT_PATH"

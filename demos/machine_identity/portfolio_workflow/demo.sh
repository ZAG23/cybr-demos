#!/bin/bash
# shellcheck disable=SC2059
set -euo pipefail

demo_path="$CYBR_DEMOS_PATH/demos/machine_identity/portfolio_workflow"

set -a
source "$CYBR_DEMOS_PATH/demos/setup_env.sh"
source "$CYBR_DEMOS_PATH/demos/utility/ubuntu/demo_utility.sh"
source "$demo_path/setup/vars.env"
set +a

#==============================================================================
# Helper: pause between demo stages
#==============================================================================
pause_demo() {
  printf "\n${IBlack}Press ENTER to continue...${Color_Off}"
  read -r
  printf "\n"
}

#==============================================================================
# BANNER
#==============================================================================
clear
printf "${BWhite}"
printf "╔══════════════════════════════════════════════════════════════════════╗\n"
printf "║         CyberArk Machine Identity Portfolio — Unified Demo         ║\n"
printf "╚══════════════════════════════════════════════════════════════════════╝\n"
printf "${Color_Off}\n"

printf "${Cyan}Scenario:${Color_Off} A containerized microservice and its AI agents need to:\n"
printf "  1. Authenticate their identity to CyberArk\n"
printf "  2. Retrieve application secrets from Conjur Cloud\n"
printf "  3. Obtain TLS certificates — three approaches:\n"
printf "     a. Ephemeral workload certs via Conjur Cloud PKI\n"
printf "     b. Full lifecycle (request/renew/revoke) via VCert SDK\n"
printf "     c. Kubernetes-native automation via cert-manager + CyberArk Issuer\n"
printf "  4. Verify secrets are synced to cloud-native stores via Secrets Hub\n"
printf "  5. Access infrastructure via just-in-time SSH certificates (SIA)\n"
printf "  6. Elevate cloud permissions via just-in-time access (SCA)\n"
printf "  7. Secure AI agent identities via the AI Gateway\n"
printf "\n"
printf "${IBlack}Tenant: %s | Lab: %s${Color_Off}\n" "$TENANT_SUBDOMAIN" "$LAB_ID"
print_line

pause_demo

#==============================================================================
# STEP 1: ISPSS Platform Authentication
#==============================================================================
printf "${BYellow}STEP 1: ISPSS Platform Authentication${Color_Off}\n"
printf "${IBlack}Authenticate service account via OAuth2 client_credentials flow${Color_Off}\n\n"

print_prompt "curl -s -X POST https://$TENANT_ID.id.cyberark.cloud/oauth2/platformtoken ..."

identity_token=$(get_identity_token "$TENANT_ID" "$CLIENT_ID" "$CLIENT_SECRET")

printf "${Green}Identity token acquired${Color_Off} (%s...)\n" "${identity_token:0:20}"
printf "\n${IBlack}This token authenticates to all ISPSS services:${Color_Off}\n"
printf "  Privilege Cloud | Conjur Cloud | Secrets Hub | SIA | SCA\n"
print_line

pause_demo

#==============================================================================
# STEP 2: Conjur Cloud — Workload Authentication
#==============================================================================
printf "${BYellow}STEP 2: Conjur Cloud — Workload Authentication${Color_Off}\n"
printf "${IBlack}Exchange ISPSS token for a Conjur session token (OIDC authn)${Color_Off}\n\n"

print_prompt "curl -s -X POST https://$TENANT_SUBDOMAIN.secretsmgr.cyberark.cloud/api/authn-oidc/cyberark/conjur/authenticate ..."

conjur_token=$(get_conjur_token "$TENANT_SUBDOMAIN" "$identity_token")

printf "${Green}Conjur token acquired${Color_Off} (%s...)\n" "${conjur_token:0:20}"
printf "\n${IBlack}Supported workload authenticators:${Color_Off}\n"
printf "  JWT/OIDC | Kubernetes | AWS IAM | Azure | GCP\n"
print_line

pause_demo

#==============================================================================
# STEP 3: Conjur Cloud — Fetch Secrets
#==============================================================================
printf "${BYellow}STEP 3: Conjur Cloud — Fetch Application Secrets${Color_Off}\n"
printf "${IBlack}Retrieve secrets the workload is authorized to access${Color_Off}\n\n"

secrets_to_fetch=(
  "$SM_SECRET_DB_USER_ID|DB Username"
  "$SM_SECRET_DB_PASS_ID|DB Password"
  "$SM_SECRET_API_KEY_ID|API Key"
)

for entry in "${secrets_to_fetch[@]}"; do
  secret_id="${entry%%|*}"
  secret_label="${entry##*|}"

  encoded_id=$(printf '%s' "$secret_id" | sed 's|/|%2F|g')
  print_prompt "curl -s https://$TENANT_SUBDOMAIN.secretsmgr.cyberark.cloud/api/secrets/conjur/variable/$encoded_id"

  secret_value=$(curl --silent \
    --location "https://$TENANT_SUBDOMAIN.secretsmgr.cyberark.cloud/api/secrets/conjur/variable/$encoded_id" \
    --header "Authorization: Token token=\"$conjur_token\"")

  if [ -n "$secret_value" ] && [ "$secret_value" != "null" ]; then
    masked="${secret_value:0:3}$(printf '*%.0s' $(seq 1 $((${#secret_value} - 3))))"
    printf "  ${Green}%s:${Color_Off} %s\n" "$secret_label" "$masked"
  else
    printf "  ${Red}%s:${Color_Off} (not found — run setup.sh first)\n" "$secret_label"
  fi
done

printf "\n${IBlack}Secrets are fetched at runtime — never stored on disk${Color_Off}\n"
print_line

pause_demo

#==============================================================================
# STEP 4a: Conjur Cloud PKI — Ephemeral Workload Certificates
#==============================================================================
printf "${BYellow}STEP 4a: Conjur Cloud PKI — Ephemeral Workload Certificates${Color_Off}\n"
printf "${IBlack}Short-lived certs tied to Conjur workload identity — no CA infra needed${Color_Off}\n\n"

printf "${Cyan}Use case:${Color_Off}    Microservice mTLS, service mesh sidecar certs\n"
printf "${Cyan}Common Name:${Color_Off} %s\n" "$PKI_COMMON_NAME"
printf "${Cyan}TTL:${Color_Off}         %s seconds\n\n" "$PKI_TTL"

print_prompt "curl -s -X POST https://$TENANT_SUBDOMAIN.secretsmgr.cyberark.cloud/api/ca/conjur/issue ..."

cert_response=$(curl --silent \
  --location "https://$TENANT_SUBDOMAIN.secretsmgr.cyberark.cloud/api/ca/conjur/issue" \
  --header "Authorization: Token token=\"$conjur_token\"" \
  --header 'Content-Type: application/json' \
  --data "{
    \"commonName\": \"$PKI_COMMON_NAME\",
    \"ttl\": $PKI_TTL
  }" 2>&1 || true)

if printf '%s' "$cert_response" | grep -q "BEGIN CERTIFICATE"; then
  printf "${Green}Certificate issued successfully${Color_Off}\n"
  printf '%s' "$cert_response" | openssl x509 -noout -subject -dates 2>/dev/null || true
else
  printf "${Yellow}PKI not configured on this tenant — showing capability overview${Color_Off}\n"
  printf "${IBlack}When enabled:${Color_Off}\n"
  printf "  - Conjur acts as a lightweight CA for workloads\n"
  printf "  - Certs are short-lived (minutes to hours) — no sprawl\n"
  printf "  - Workloads authenticate with their existing Conjur identity\n"
fi

printf "\n${IBlack}Best for: ephemeral, high-volume workload-to-workload mTLS${Color_Off}\n"
print_line

pause_demo

#==============================================================================
# STEP 4b: VCert SDK — Programmatic Certificate Lifecycle
#==============================================================================
printf "${BYellow}STEP 4b: VCert Python SDK — Full Certificate Lifecycle${Color_Off}\n"
printf "${IBlack}Request → Retrieve → Renew → Revoke via CyberArk Certificate Manager${Color_Off}\n\n"

printf "${Cyan}Use case:${Color_Off}    Application-embedded cert management, CI/CD pipelines\n"
printf "${Cyan}Common Name:${Color_Off} %s\n" "$VCERT_COMMON_NAME"
printf "${Cyan}Zone:${Color_Off}        %s\n\n" "$VCERT_ZONE"

if [ -n "${VCERT_API_KEY:-}" ]; then
  printf "${Green}Mode: CyberArk Certificate Manager SaaS${Color_Off}\n\n"
elif [ -n "${VCERT_TPP_URL:-}" ]; then
  printf "${Green}Mode: CyberArk Certificate Manager Self-Hosted${Color_Off} (%s)\n\n" "$VCERT_TPP_URL"
else
  printf "${Yellow}Mode: Fake (demo) — set VCERT_API_KEY or VCERT_TPP_* for live${Color_Off}\n\n"
fi

print_prompt "python3 setup/vcert/vcert_lifecycle.py full"

if command -v python3 >/dev/null 2>&1 && python3 -c "import vcert" 2>/dev/null; then
  python3 "$demo_path/setup/vcert/vcert_lifecycle.py" full 2>&1 || true
else
  printf "${Yellow}vcert SDK not installed — run: pip3 install vcert${Color_Off}\n"
  printf "${IBlack}The VCert SDK supports the full certificate lifecycle:${Color_Off}\n"
  printf "  1. ${Cyan}Request${Color_Off}  — Submit CSR with subject, SANs, key type\n"
  printf "  2. ${Cyan}Retrieve${Color_Off} — Fetch signed cert + chain + private key\n"
  printf "  3. ${Cyan}Renew${Color_Off}    — Generate new cert with same subject\n"
  printf "  4. ${Cyan}Revoke${Color_Off}   — Invalidate cert (Self-Hosted/TPP only)\n"
fi

printf "\n${IBlack}Best for: apps that manage their own certs, automation pipelines, non-K8s workloads${Color_Off}\n"

printf "\n${IBlack}Code example:${Color_Off}\n"
printf "${Cyan}  from vcert import venafi_connection, CertificateRequest${Color_Off}\n"
printf "${Cyan}  conn = venafi_connection(api_key=\"...\")${Color_Off}\n"
printf "${Cyan}  req = CertificateRequest(common_name=\"app.example.com\")${Color_Off}\n"
printf "${Cyan}  conn.request_cert(req, zone)${Color_Off}\n"
printf "${Cyan}  cert = conn.retrieve_cert(req)${Color_Off}\n"
print_line

pause_demo

#==============================================================================
# STEP 4c: cert-manager — Kubernetes-Native Certificate Automation
#==============================================================================
printf "${BYellow}STEP 4c: cert-manager + CyberArk Issuer — Kubernetes-Native Automation${Color_Off}\n"
printf "${IBlack}Automatic provisioning and renewal of TLS certs for K8s workloads${Color_Off}\n\n"

printf "${Cyan}Use case:${Color_Off}    Ingress TLS, service-to-service mTLS, SPIFFE identities\n"
printf "${Cyan}Namespace:${Color_Off}   %s\n" "$CM_NAMESPACE"
printf "${Cyan}Common Name:${Color_Off} %s\n" "$CM_CERT_COMMON_NAME"
printf "${Cyan}Secret:${Color_Off}      %s\n\n" "$CM_CERT_SECRET_NAME"

if command -v kubectl >/dev/null 2>&1 && kubectl cluster-info >/dev/null 2>&1; then
  # Show the CyberArk Issuer
  print_prompt "kubectl get issuers -n $CM_NAMESPACE"
  kubectl get issuers -n "$CM_NAMESPACE" 2>/dev/null || printf "  ${Yellow}No issuers found in namespace${Color_Off}\n"

  printf "\n"

  # Show the Certificate resource
  print_prompt "kubectl get certificates -n $CM_NAMESPACE"
  kubectl get certificates -n "$CM_NAMESPACE" 2>/dev/null || printf "  ${Yellow}No certificates found in namespace${Color_Off}\n"

  printf "\n"

  # Show the TLS secret
  print_prompt "kubectl get secret $CM_CERT_SECRET_NAME -n $CM_NAMESPACE -o jsonpath='{.data}' | jq -r 'keys'"
  tls_secret=$(kubectl get secret "$CM_CERT_SECRET_NAME" -n "$CM_NAMESPACE" -o jsonpath='{.data}' 2>/dev/null || echo "")
  if [ -n "$tls_secret" ]; then
    printf "${Green}TLS secret exists with keys:${Color_Off} "
    printf '%s' "$tls_secret" | jq -r 'keys | join(", ")' 2>/dev/null || true
    printf "\n"

    # Decode and show cert details
    tls_cert=$(kubectl get secret "$CM_CERT_SECRET_NAME" -n "$CM_NAMESPACE" \
      -o jsonpath='{.data.tls\.crt}' 2>/dev/null | base64 -d 2>/dev/null || true)
    if [ -n "$tls_cert" ]; then
      printf "\n${Cyan}Certificate details:${Color_Off}\n"
      printf '%s' "$tls_cert" | openssl x509 -noout -subject -issuer -dates 2>/dev/null | sed 's/^/  /' || true
    fi
  else
    printf "  ${Yellow}TLS secret not yet created — certificate may be pending issuance${Color_Off}\n"
  fi
else
  printf "${Yellow}No Kubernetes cluster available — showing configuration overview${Color_Off}\n"
fi

printf "\n${IBlack}How it works:${Color_Off}\n"
printf "  1. Deploy a CyberArk ${Cyan}Issuer${Color_Off} (SaaS or Self-Hosted)\n"
printf "  2. Create a ${Cyan}Certificate${Color_Off} resource with desired CN, SANs, duration\n"
printf "  3. cert-manager requests the cert from CyberArk Certificate Manager\n"
printf "  4. Signed cert + key land in a K8s ${Cyan}Secret${Color_Off} (auto-renewed)\n"

printf "\n${IBlack}Issuer types supported:${Color_Off}\n"
printf "  CyberArk SaaS (API key) | CyberArk Self-Hosted/TPP (token or user/pass)\n"

printf "\n${IBlack}Best for: Ingress TLS, K8s-native workloads, GitOps cert management${Color_Off}\n"
print_line

pause_demo

#==============================================================================
# STEP 4 — Certificate Options Comparison
#==============================================================================
printf "${BWhite}"
printf "╔══════════════════════════════════════════════════════════════════════╗\n"
printf "║              Certificate Options — Side by Side                     ║\n"
printf "╚══════════════════════════════════════════════════════════════════════╝\n"
printf "${Color_Off}\n"

printf "${BWhite}%-14s %-26s %-20s %-20s${Color_Off}\n" "" "Conjur Cloud PKI" "VCert SDK" "cert-manager"
printf "─────────────────────────────────────────────────────────────────────────────────\n"
printf "${Cyan}%-14s${Color_Off} %-26s %-20s %-20s\n" "Approach"    "API call to Conjur CA"    "Python/Go/Java SDK"  "K8s CRD + controller"
printf "${Cyan}%-14s${Color_Off} %-26s %-20s %-20s\n" "Cert TTL"    "Minutes to hours"         "Days to years"       "Configurable (hours+)"
printf "${Cyan}%-14s${Color_Off} %-26s %-20s %-20s\n" "Renewal"     "Re-request on expiry"     "SDK renew_cert()"    "Automatic by controller"
printf "${Cyan}%-14s${Color_Off} %-26s %-20s %-20s\n" "Revocation"  "N/A (short-lived)"        "SDK (TPP only)"      "N/A (re-issue)"
printf "${Cyan}%-14s${Color_Off} %-26s %-20s %-20s\n" "Best for"    "Ephemeral workloads"      "CI/CD, non-K8s apps" "K8s Ingress, mesh"
printf "${Cyan}%-14s${Color_Off} %-26s %-20s %-20s\n" "Identity"    "Conjur workload authn"    "API key / TPP token" "K8s Secret ref"
printf "${Cyan}%-14s${Color_Off} %-26s %-20s %-20s\n" "CA Backend"  "Conjur built-in CA"       "CyberArk Cert Mgr"   "CyberArk Cert Mgr"
printf "─────────────────────────────────────────────────────────────────────────────────\n"
printf "\n${IBlack}All three options are governed by CyberArk policy and produce auditable events.${Color_Off}\n"
print_line

pause_demo

#==============================================================================
# STEP 5: Secrets Hub — Cloud-Native Secret Sync
#==============================================================================
printf "${BYellow}STEP 5: Secrets Hub — Verify Cloud-Native Sync${Color_Off}\n"
printf "${IBlack}Secrets Hub syncs Privilege Cloud secrets to native cloud stores${Color_Off}\n\n"

print_prompt "curl -s https://$TENANT_SUBDOMAIN.secretshub.cyberark.cloud/api/policies ..."

policies_response=$(curl --silent --location \
  "https://$TENANT_SUBDOMAIN.secretshub.cyberark.cloud/api/policies" \
  --header "Authorization: Bearer $identity_token" 2>&1 || true)

policy_count=$(printf '%s' "$policies_response" | jq 'length' 2>/dev/null || echo "0")

if [ "$policy_count" -gt 0 ]; then
  printf "${Green}Active sync policies: %s${Color_Off}\n\n" "$policy_count"
  printf '%s' "$policies_response" | jq -r '.[] | "  \(.name) — \(.source.type // "PAM") → \(.target.type // "unknown") [\(.status // "active")]"' 2>/dev/null || true
else
  printf "${Yellow}No sync policies found${Color_Off}\n"
fi

printf "\n${IBlack}Supported target stores:${Color_Off}\n"
printf "  AWS Secrets Manager | Azure Key Vault | GCP Secret Manager | HashiCorp Vault\n"

print_prompt "curl -s https://$TENANT_SUBDOMAIN.secretshub.cyberark.cloud/api/secret-stores ..."

stores_response=$(curl --silent --location \
  "https://$TENANT_SUBDOMAIN.secretshub.cyberark.cloud/api/secret-stores" \
  --header "Authorization: Bearer $identity_token" 2>&1 || true)

store_count=$(printf '%s' "$stores_response" | jq 'length' 2>/dev/null || echo "0")

if [ "$store_count" -gt 0 ]; then
  printf "${Green}Configured secret stores: %s${Color_Off}\n" "$store_count"
  printf '%s' "$stores_response" | jq -r '.[] | "  [\(.type)] \(.name)"' 2>/dev/null || true
fi
print_line

pause_demo

#==============================================================================
# STEP 6: Secure Infrastructure Access — JIT SSH
#==============================================================================
printf "${BYellow}STEP 6: Secure Infrastructure Access (SIA) — JIT SSH Certificates${Color_Off}\n"
printf "${IBlack}SIA provides zero-standing-privilege access to infrastructure${Color_Off}\n\n"

print_prompt "curl -s https://$TENANT_SUBDOMAIN.dpa.cyberark.cloud/api/public/connections/targets ..."

sia_response=$(curl --silent --location \
  "https://$TENANT_SUBDOMAIN.dpa.cyberark.cloud/api/public/connections/targets" \
  --header "Authorization: Bearer $identity_token" 2>&1 || true)

target_count=$(printf '%s' "$sia_response" | jq '.items | length' 2>/dev/null || echo "0")

if [ "$target_count" -gt 0 ]; then
  printf "${Green}SIA targets configured: %s${Color_Off}\n\n" "$target_count"
  printf '%s' "$sia_response" | jq -r '.items[] | "  \(.name) — \(.address) [\(.platform_type // "unknown")]"' 2>/dev/null || true
else
  printf "${Yellow}No SIA targets found (configure SIA_TARGET_HOST in vars.env)${Color_Off}\n"
fi

printf "\n${IBlack}SIA capabilities:${Color_Off}\n"
printf "  - Short-lived SSH certificates (no standing keys on targets)\n"
printf "  - Just-in-time database access with strong accounts\n"
printf "  - Session isolation and recording\n"
printf "  - Zero-standing-privilege across cloud and on-prem\n"
print_line

pause_demo

#==============================================================================
# STEP 7: Secure Cloud Access — JIT Cloud Entitlements
#==============================================================================
printf "${BYellow}STEP 7: Secure Cloud Access (SCA) — JIT Cloud Entitlements${Color_Off}\n"
printf "${IBlack}Elevate cloud permissions on-demand with time-bounded access${Color_Off}\n\n"

print_prompt "curl -s https://$TENANT_SUBDOMAIN.dpa.cyberark.cloud/api/access-policies ..."

sca_response=$(curl --silent --location \
  "https://$TENANT_SUBDOMAIN.dpa.cyberark.cloud/api/access-policies" \
  --header "Authorization: Bearer $identity_token" 2>&1 || true)

policy_count=$(printf '%s' "$sca_response" | jq '.items | length' 2>/dev/null || echo "0")

if [ "$policy_count" -gt 0 ]; then
  printf "${Green}Access policies: %s${Color_Off}\n\n" "$policy_count"
  printf '%s' "$sca_response" | jq -r '.items[] | "  \(.name) — \(.status // "active")"' 2>/dev/null || true
else
  printf "${Yellow}No SCA access policies found${Color_Off}\n"
fi

printf "\n${IBlack}SCA capabilities:${Color_Off}\n"
printf "  - Just-in-time elevation to AWS/Azure/GCP roles\n"
printf "  - Time-bounded sessions with automatic revocation\n"
printf "  - Approval workflows and audit trail\n"
printf "  - Eliminates persistent cloud admin credentials\n"
print_line

pause_demo

#==============================================================================
# STEP 8: Secure AI Agents — Agentic Identity Lifecycle
#==============================================================================
printf "${BYellow}STEP 8: Secure AI Agents — Agentic Identity Lifecycle${Color_Off}\n"
printf "${IBlack}Register, manage, and secure AI agent identities on the platform${Color_Off}\n\n"

printf "${Cyan}API:${Color_Off} https://$TENANT_SUBDOMAIN.cyberark.cloud/api/agents\n"
printf "${Cyan}Agent types:${Color_Off} COPILOT | CLAUDE | CUSTOM\n\n"

# List registered agents
print_prompt "curl -s https://$TENANT_SUBDOMAIN.cyberark.cloud/api/agents -H 'Accept: application/x.agents.beta+json'"

sai_response=$(curl --silent --location \
  "https://$TENANT_SUBDOMAIN.cyberark.cloud/api/agents" \
  --header "Authorization: Bearer $identity_token" \
  --header "Accept: application/x.agents.beta+json" 2>&1 || true)

agent_count=$(printf '%s' "$sai_response" | jq '.agents | length' 2>/dev/null || echo "0")

if [ "$agent_count" -gt 0 ]; then
  printf "${Green}Registered AI agents: %s${Color_Off}\n\n" "$agent_count"
  printf '%s' "$sai_response" | jq -r '.agents[] | "  \(.name) [\(.type)] — \(.status) (id: \(.id[0:8])...)"' 2>/dev/null || true

  # Show detail for first agent
  first_agent_id=$(printf '%s' "$sai_response" | jq -r '.agents[0].id' 2>/dev/null || true)
  if [ -n "$first_agent_id" ] && [ "$first_agent_id" != "null" ]; then
    printf "\n"
    print_prompt "curl -s https://$TENANT_SUBDOMAIN.cyberark.cloud/api/agents/$first_agent_id"

    agent_detail=$(curl --silent --location \
      "https://$TENANT_SUBDOMAIN.cyberark.cloud/api/agents/$first_agent_id" \
      --header "Authorization: Bearer $identity_token" \
      --header "Accept: application/x.agents.beta+json" 2>&1 || true)

    printf "\n${Cyan}Agent details:${Color_Off}\n"
    printf '%s' "$agent_detail" | jq '{
      name: .name,
      type: .type,
      status: .status,
      description: .description,
      createdAt: .createdAt,
      tags: .tags
    }' 2>/dev/null | sed 's/^/  /' || true
  fi
else
  printf "${Yellow}No AI agents registered${Color_Off}\n"
  printf "${IBlack}Set SAI_AGENT_NAME in vars.env and run setup.sh to register one${Color_Off}\n"
fi

printf "\n${IBlack}Secure AI Agents lifecycle:${Color_Off}\n"
printf "  1. ${Cyan}Register${Color_Off}  — POST /api/agents → clientId + clientSecret + gatewayUrl\n"
printf "  2. ${Cyan}Configure${Color_Off} — Connect agent to CyberArk gateway\n"
printf "  3. ${Cyan}Activate${Color_Off}  — PATCH /api/agents/{id}/state → ACTIVE\n"
printf "  4. ${Cyan}Monitor${Color_Off}   — Track agent activity, secrets access, sessions\n"
printf "  5. ${Cyan}Suspend${Color_Off}   — PATCH /api/agents/{id}/state → SUSPENDED\n"

printf "\n${IBlack}Agent identity model:${Color_Off}\n"
printf "  - Each AI agent gets a unique ${Cyan}clientId${Color_Off} + ${Cyan}clientSecret${Color_Off}\n"
printf "  - Agent authenticates through a dedicated ${Cyan}gatewayUrl${Color_Off}\n"
printf "  - CyberArk enforces policy on what secrets/resources the agent can access\n"
printf "  - Full audit trail of agent actions across the platform\n"

printf "\n${BWhite}AI Gateway — MCP Server Inventory${Color_Off}\n\n"
printf "${IBlack}The AI Gateway proxies agent access to tools via MCP servers${Color_Off}\n\n"

print_prompt "curl -s https://$TENANT_SUBDOMAIN-aigw.cyberark.cloud/api/targets/mcp-servers -H 'Accept: application/x.targets.beta+json'"

aigw_response=$(curl --silent --location \
  "https://$TENANT_SUBDOMAIN-aigw.cyberark.cloud/api/targets/mcp-servers" \
  --header "Authorization: Bearer $identity_token" \
  --header "Accept: application/x.targets.beta+json" 2>&1 || true)

mcp_count=$(printf '%s' "$aigw_response" | jq 'if type == "array" then length elif .items then (.items | length) else 0 end' 2>/dev/null || echo "0")

if [ "$mcp_count" -gt 0 ]; then
  printf "${Green}MCP servers registered: %s${Color_Off}\n\n" "$mcp_count"
  # Handle both array and .items response shapes
  printf '%s' "$aigw_response" | jq -r '
    (if type == "array" then . elif .items then .items else [] end)[]
    | "  \(.name) [\(.category // "unknown")] — \(.upstream.url // "n/a")"
  ' 2>/dev/null || true
else
  printf "${Yellow}No MCP servers registered in AI Gateway${Color_Off}\n"
fi

printf "\n${IBlack}AI Gateway capabilities:${Color_Off}\n"
printf "  - Proxies AI agent tool calls through CyberArk-secured MCP servers\n"
printf "  - Supports ${Cyan}SIA DB MCP${Color_Off} for database access via agents\n"
printf "  - Auth methods: OAuth 2.1, passthrough, or CyberArk as IdP\n"
printf "  - Portal: https://$TENANT_SUBDOMAIN.cyberark.cloud/adminportal/aigw/mcp/inventory\n"

printf "\n${IBlack}Required roles:${Color_Off}\n"
printf "  ${Cyan}Secure AI Admins${Color_Off}    — Full SAI administration\n"
printf "  ${Cyan}Secure AI Builders${Color_Off}  — Agent registration and gateway config\n"
print_line

pause_demo

#==============================================================================
# SUMMARY
#==============================================================================
printf "${BWhite}"
printf "╔══════════════════════════════════════════════════════════════════════╗\n"
printf "║                      Portfolio Summary                              ║\n"
printf "╚══════════════════════════════════════════════════════════════════════╝\n"
printf "${Color_Off}\n"

printf "${BWhite}Component                          What We Demonstrated${Color_Off}\n"
printf "──────────────────────────────────────────────────────────────────────\n"
printf "${Cyan}ISPSS Platform Auth${Color_Off}                OAuth2 service account token\n"
printf "${Cyan}Conjur Cloud (Secrets Mgr)${Color_Off}         Workload authn + secret retrieval\n"
printf "${Cyan}Conjur Cloud (PKI)${Color_Off}                 Ephemeral short-lived workload certs\n"
printf "${Cyan}CyberArk Cert Mgr (VCert SDK)${Color_Off}      Request → retrieve → renew → revoke\n"
printf "${Cyan}cert-manager + CyberArk Issuer${Color_Off}     K8s-native cert automation + auto-renew\n"
printf "${Cyan}Secrets Hub${Color_Off}                        PAM → cloud-native secret sync\n"
printf "${Cyan}Secure Infra Access (SIA)${Color_Off}          JIT SSH certificates, zero standing access\n"
printf "${Cyan}Secure Cloud Access (SCA)${Color_Off}          JIT cloud role elevation\n"
printf "${Cyan}Secure AI Agents${Color_Off}                   Agentic identity lifecycle + gateway\n"
printf "──────────────────────────────────────────────────────────────────────\n"

printf "\n${BWhite}Certificate Strategy:${Color_Off}\n"
printf "  ${Cyan}Ephemeral workloads${Color_Off}  → Conjur Cloud PKI (minutes, API-driven)\n"
printf "  ${Cyan}App-embedded certs${Color_Off}   → VCert SDK (full lifecycle, any platform)\n"
printf "  ${Cyan}Kubernetes workloads${Color_Off} → cert-manager + CyberArk Issuer (auto-renew)\n"

printf "\n${BWhite}Identity Types Secured:${Color_Off}\n"
printf "  ${Cyan}Applications${Color_Off}    → Conjur workload identity + secrets\n"
printf "  ${Cyan}Infrastructure${Color_Off}  → SIA JIT SSH certs + SCA cloud roles\n"
printf "  ${Cyan}AI Agents${Color_Off}       → Secure AI agent identity + gateway\n"

printf "\n${IBlack}All components share a single identity platform and unified audit.${Color_Off}\n"
printf "${IBlack}Machine identities are secured end-to-end: secrets, certificates,${Color_Off}\n"
printf "${IBlack}infrastructure access, cloud entitlements, and AI agent identities.${Color_Off}\n\n"

printf "${Green}Demo complete.${Color_Off}\n\n"

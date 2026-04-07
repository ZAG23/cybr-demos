#!/bin/bash
set -euo pipefail

source "$CYBR_DEMOS_PATH/demos/utility/ubuntu/identity_functions.sh"

printf "\n[INFO] Secure AI Agents: Authenticating\n"
identity_token=$(get_identity_token "$TENANT_ID" "$CLIENT_ID" "$CLIENT_SECRET")

if [ -z "${SAI_AGENT_NAME:-}" ]; then
  printf "[WARN] Secure AI Agents: SAI_AGENT_NAME not set in vars.env — skipping\n"
  printf "[INFO] Secure AI Agents: Set SAI_AGENT_NAME and SAI_AGENT_TYPE to enable\n"
  exit 0
fi

# Check if agent already exists
printf "[INFO] Secure AI Agents: Checking for existing agent '%s'\n" "$SAI_AGENT_NAME"
existing=$(curl --silent --location \
  "https://$TENANT_SUBDOMAIN.cyberark.cloud/api/agents" \
  --header "Authorization: Bearer $identity_token" \
  --header "Accept: application/x.agents.beta+json" 2>&1 || true)

existing_id=$(printf '%s' "$existing" | jq -r ".agents[]? | select(.name == \"$SAI_AGENT_NAME\") | .id // empty" 2>/dev/null || true)

if [ -n "$existing_id" ]; then
  printf "[INFO] Secure AI Agents: Agent '%s' already registered (id: %s)\n" "$SAI_AGENT_NAME" "$existing_id"
  printf "[INFO] Secure AI Agents: Setup complete (skipping registration)\n"
  exit 0
fi

# Register the AI agent
printf "[INFO] Secure AI Agents: Registering agent '%s' (type: %s)\n" "$SAI_AGENT_NAME" "$SAI_AGENT_TYPE"

register_payload=$(jq -cn \
  --arg name "$SAI_AGENT_NAME" \
  --arg type "$SAI_AGENT_TYPE" \
  --arg desc "$SAI_AGENT_DESCRIPTION" \
  --arg cb "$SAI_CALLBACK_URL" \
  '{
    name: $name,
    type: $type,
    description: $desc,
    redirectCallbackUrls: [$cb],
    tags: {
      environment: "demo",
      managed_by: "cybr-demos"
    }
  }')

register_response=$(curl --silent --location \
  "https://$TENANT_SUBDOMAIN.cyberark.cloud/api/agents" \
  --header "Authorization: Bearer $identity_token" \
  --header "Accept: application/x.agents.beta+json" \
  --header "Content-Type: application/json" \
  --data "$register_payload")

agent_id=$(printf '%s' "$register_response" | jq -r '.id // empty')
client_id=$(printf '%s' "$register_response" | jq -r '.credentials.clientId // empty')
gateway_url=$(printf '%s' "$register_response" | jq -r '.credentials.gatewayUrl // empty')

if [ -z "$agent_id" ]; then
  printf "[ERROR] Secure AI Agents: Registration failed\n%s\n" "$register_response"
  exit 1
fi

printf "[INFO] Secure AI Agents: Agent registered (id: %s)\n" "$agent_id"
printf "[INFO] Secure AI Agents: Client ID: %s\n" "$client_id"
printf "[INFO] Secure AI Agents: Gateway URL: %s\n" "$gateway_url"

# Activate the agent
printf "[INFO] Secure AI Agents: Activating agent\n"
curl --silent --location \
  "https://$TENANT_SUBDOMAIN.cyberark.cloud/api/agents/$agent_id/state" \
  --request PATCH \
  --header "Authorization: Bearer $identity_token" \
  --header "Accept: application/x.agents.beta+json" \
  --header "Content-Type: application/json" \
  --data '{"state": "ACTIVE"}' >/dev/null 2>&1 || printf "[INFO] Secure AI Agents: Agent may require configuration before activation\n"

# Register SIA DB MCP server in AI Gateway (if SAI_AIGW_SIA_MCP_URL is set)
if [ -n "${SAI_AIGW_SIA_MCP_URL:-}" ]; then
  printf "\n[INFO] AI Gateway: Registering SIA DB MCP server\n"

  mcp_payload=$(jq -cn \
    --arg url "$SAI_AIGW_SIA_MCP_URL" \
    '{
      name: "SIA_DB_MCP_SERVER",
      description: "SIA DB MCP - provisioned by cybr-demos",
      category: "DATABASES_AND_DATA_STORES",
      source: { type: "CUSTOM" },
      upstream: { url: $url },
      authMethod: { type: "OAUTH2.1" }
    }')

  mcp_response=$(curl --silent --location \
    "https://$TENANT_SUBDOMAIN-aigw.cyberark.cloud/api/targets/mcp-servers" \
    --header "Authorization: Bearer $identity_token" \
    --header "Accept: application/x.targets.beta+json" \
    --header "Content-Type: application/json" \
    --data "$mcp_payload" 2>&1 || true)

  mcp_id=$(printf '%s' "$mcp_response" | jq -r '.id // empty' 2>/dev/null || true)
  if [ -n "$mcp_id" ]; then
    printf "[INFO] AI Gateway: SIA DB MCP server registered (id: %s)\n" "$mcp_id"
  else
    printf "[WARN] AI Gateway: MCP registration response: %s\n" "$mcp_response"
  fi
fi

printf "[INFO] Secure AI Agents: Setup complete\n"

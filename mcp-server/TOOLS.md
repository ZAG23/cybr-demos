# MCP Server Tools Reference

Five tools are available. The CLI under `tools/cli/` is the source of truth for behavior. If this document conflicts with the CLI, update this file.

---

## create_demo

Scaffolds a new demo directory with README.md, info.yaml, demo.sh, setup.sh, and setup/configure.sh. All scripts are made executable with proper shebangs, error handling, and env var sourcing.

**CLI:** `node tools/cli/cybr-demos.js create-demo`

### Parameters

| Parameter | Type | Required | Description |
|-----------|------|----------|-------------|
| `category` | string (enum) | Yes | `credential_providers`, `secrets_manager`, `secrets_hub`, or `utility` |
| `name` | string | Yes | Demo name (converted to lowercase with underscores for directory) |
| `displayName` | string | No | Display name for README/info.yaml. Defaults to `name`. |
| `categoryLabel` | string | No | Custom category label for info.yaml. Defaults to `category`. |
| `description` | string | No | Description for README About section. |
| `docs` | string | No | Documentation URL. Defaults to CyberArk docs portal. |
| `demoScript` | string | No | Demo script filename. Defaults to `demo.sh`. |
| `setupScript` | string | No | Setup script filename. Defaults to `setup.sh`. |

### Output

```
demos/{category}/{demo_name}/
├── README.md
├── info.yaml
├── demo.sh
├── setup.sh
└── setup/
    └── configure.sh
```

---

## create_demo_safe

Generates a `setup/vault/` directory with scripts to create and configure a CyberArk Privilege Cloud safe. Requires an existing demo directory.

**CLI:** `node tools/cli/cybr-demos.js create-demo-safe`

### Parameters

| Parameter | Type | Required | Description |
|-----------|------|----------|-------------|
| `demoPath` | string | Yes | Path relative to `demos/` (e.g., `secrets_manager/azure_devops`) |
| `safeName` | string | No | Safe name. Defaults to `${LAB_ID}-{demo-name}` (normalized). |
| `addSyncMember` | boolean | No | Add "Conjur Sync" read member. Defaults to `true` for `secrets_manager` demos. |
| `createAccount` | boolean | No | Include test SSH account creation. Defaults to `false`. |
| `setupConjur` | boolean | No | Include Conjur synchronizer setup. Defaults to `false`. |
| `additionalVars` | string | No | Extra env vars for `vars.env` (multiline shell definitions). |

### Output

```
demos/{category}/{demo_name}/
└── setup/
    ├── vars.env
    └── vault/
        └── setup.sh
```

Generated scripts depend on: `demos/setup_env.sh`, `demos/tenant_vars.sh`, and utility functions in `demos/utility/ubuntu/` (identity, privilege, conjur).

---

## provision_safe

Executes live API calls to create a safe in CyberArk Privilege Cloud. Unlike `create_demo_safe` (which generates scripts), this tool provisions immediately using env vars from `tenant_vars.sh`.

**CLI:** `node tools/cli/cybr-demos.js provision-safe`

### Parameters

| Parameter | Type | Required | Description |
|-----------|------|----------|-------------|
| `demoPath` | string | Yes | Path relative to `demos/` |
| `safeName` | string | Yes | Safe name (e.g., `poc-azure-devops`) |
| `addSyncMember` | boolean | No | Add "Conjur Sync" member. Defaults to `false`. |
| `createAccounts` | boolean | No | Create test SSH account (`account-ssh-user-1`). Defaults to `false`. |
| `setupConjur` | boolean | No | Wait for Conjur synchronizer. Requires `addSyncMember`. Defaults to `false`. |

### Execution flow

1. Authenticate to CyberArk Identity (OAuth)
2. Create safe via Privilege Cloud API
3. Add admin role permissions
4. Optionally: add Conjur Sync member, create test accounts, wait for sync

### Requires

- `CYBR_DEMOS_PATH` set
- `TENANT_ID`, `TENANT_SUBDOMAIN`, `CLIENT_ID`, `CLIENT_SECRET` in `demos/tenant_vars.sh`
- Network access to CyberArk Privilege Cloud

---

## provision_workload

Creates a Secrets Manager workload with API key authentication and grants it access to an existing safe. Complements `provision_safe` -- create the safe first, then create workloads.

**CLI:** `node tools/cli/cybr-demos.js provision-workload`

### Parameters

| Parameter | Type | Required | Description |
|-----------|------|----------|-------------|
| `demoPath` | string | Yes | Path relative to `demos/` |
| `safeName` | string | Yes | Existing safe to grant access to |
| `workloadName` | string | Yes | Workload identifier (created as `data/workloads/{workloadName}`) |

### Execution flow

1. Authenticate to Identity and Conjur
2. Create workload policy (host with `authn/api-key: true`)
3. Grant workload consumer access to the safe
4. Rotate API key
5. Save credentials to `setup/.workload_credentials_{workloadName}.txt` (mode 600)

### Conjur policy created

```yaml
- !host
  id: workloads/{workloadName}
  annotations:
    authn/api-key: true
- !grant
  roles:
    - !group vault/{safeName}/delegation/consumers
  members:
    - !host workloads/{workloadName}
```

### Using the credentials

```bash
# Authenticate
TOKEN=$(curl -s -d "$API_KEY" \
  "https://$SUBDOMAIN.secretsmgr.cyberark.cloud/api/authn/conjur/host%2Fdata%2Fworkloads%2F$WORKLOAD/authenticate" \
  | base64 | tr -d '\r\n')

# Retrieve secret
curl -H "Authorization: Token token=\"$TOKEN\"" \
  "https://$SUBDOMAIN.secretsmgr.cyberark.cloud/api/secrets/conjur/variable/data%2Fvault%2F$SAFE%2F$ACCOUNT%2Fusername"
```

---

## validate_readme

Lints a markdown file against documentation guidelines. Currently checks for emoji usage; returns a score (0-100, passing is 70+) with line-level issue locations.

**CLI:** `node tools/cli/cybr-demos.js validate-readme`

### Parameters

| Parameter | Type | Required | Description |
|-----------|------|----------|-------------|
| `filePath` | string | Yes | Path relative to `demos/` (e.g., `secrets_manager/myapp/README.md`) |

### Response fields

| Field | Description |
|-------|-------------|
| `passed` | Boolean pass/fail (score >= 70) |
| `score` | 0-100. Emojis deduct 5 points each (max -30). |
| `issues` | Array of guideline violations with line numbers and previews |
| `suggestions` | Actionable fix recommendations |

---

## Global contract envelope

All tools wrap responses in:

```json
{
  "status": "ok | partial | error",
  "request_id": "uuid",
  "tool_name": "string",
  "contract_version": "global/v1",
  "duration_ms": 0,
  "result": {},
  "warnings": [],
  "errors": [],
  "meta": {
    "timestamp_utc": "ISO-8601",
    "redactions_applied": 0,
    "next_cursor": null
  }
}
```

Mutating tools (`create_demo`, `create_demo_safe`, `provision_safe`, `provision_workload`) accept optional `idempotency_key` and `dry_run` parameters. Missing idempotency keys on mutating calls produce a warning.

Errors use typed codes: `VALIDATION_FAILED`, `AUTH_FAILED`, `PERMISSION_DENIED`, `RESOURCE_NOT_FOUND`, `RESOURCE_CONFLICT`, `RATE_LIMITED`, `DEPENDENCY_UNAVAILABLE`, `INTERNAL_ERROR`. Each error includes `retryable`, `http_status`, and `remediation` fields.

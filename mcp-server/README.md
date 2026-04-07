# CyberArk Demos MCP Server

MCP server that gives AI assistants (Claude Desktop, Zed) the ability to scaffold demos, provision CyberArk safes, create Secrets Manager workloads, and validate documentation. It is a thin adapter over `tools/cli/cybr-demos.js` -- the CLI is the source of truth for all tool behavior.

## Quickstart

### Prerequisites

- Node.js 18+
- An MCP client (Claude Desktop or Zed)
- For provisioning tools: `CYBR_DEMOS_PATH` env var and configured `demos/tenant_vars.sh`

### Install

```bash
cd mcp-server
./setup.sh        # checks Node version, runs npm install, prints config snippets
```

### Configure your MCP client

**Claude Desktop** (`~/Library/Application Support/Claude/claude_desktop_config.json`):

```json
{
  "mcpServers": {
    "cybr-demos": {
      "command": "node",
      "args": ["/absolute/path/to/cybr-demos/mcp-server/index.js"]
    }
  }
}
```

**Zed** (`~/.config/zed/settings.json`):

```json
{
  "context_servers": {
    "cybr-demos": {
      "command": "node",
      "args": ["/absolute/path/to/cybr-demos/mcp-server/index.js"]
    }
  }
}
```

Use absolute paths. Get yours with `cd mcp-server && pwd`.

Restart your client after adding the config.

### Environment setup for provisioning tools

`provision_safe` and `provision_workload` execute live CyberArk API calls. They require:

```bash
# Shell profile
export CYBR_DEMOS_PATH="/path/to/cybr-demos"

# demos/tenant_vars.sh
export TENANT_ID="abc12345"
export TENANT_SUBDOMAIN="yourcompany"
export CLIENT_ID="your-client-id@cyberark.cloud.12345"
export CLIENT_SECRET="your-client-secret"
export LAB_ID="poc"   # used for default safe name generation
```

## Tools

Five tools are exposed. See [TOOLS.md](TOOLS.md) for the full parameter reference.

| Tool | Action | Mutating |
|------|--------|----------|
| `create_demo` | Scaffold a new demo directory (README, info.yaml, scripts) | Yes |
| `create_demo_safe` | Generate vault setup scripts for a demo | Yes |
| `provision_safe` | Create a safe in Privilege Cloud via API | Yes |
| `provision_workload` | Create a Secrets Manager workload with API key auth | Yes |
| `validate_readme` | Lint a markdown file against doc guidelines | No |

### Typical workflow

```
1. Create a secrets_manager demo called "myapp"
2. Provision a safe for secrets_manager/myapp with safe name "poc-myapp", add sync member true, create accounts true
3. Provision a workload for secrets_manager/myapp with safe name "poc-myapp" and workload name "myapp-prod"
```

## Architecture

```
MCP Client (Zed / Claude Desktop)
       | stdio / MCP protocol
MCP Server  (mcp-server/index.js)
       | child_process exec
CLI Layer   (tools/cli/cybr-demos.js)
       | filesystem + CyberArk APIs
demos/
```

- `tools/cli/` owns command logic, templates, and JSON output contracts.
- `tools/templates/` owns scaffold templates.
- `mcp-server/index.js` translates MCP tool calls into CLI invocations and wraps responses in a global contract envelope.

### Response contract

Every response uses a canonical envelope (request_id, contract_version, status, result, warnings, errors, meta). Sensitive values (tokens, API keys, secrets) are automatically redacted. Mutating tools support `dry_run` and `idempotency_key` parameters.

## Development

```bash
npm start                         # run server on stdio
node ../tools/cli/cybr-demos.js --help  # run CLI directly
cd ../tools/cli && npm run smoke  # CLI smoke tests
```

Templates live in `tools/templates/demo` and `tools/templates/safe`. Do not add template strings to `index.js`.

## Domain rules (summary)

These rules govern tool and script authoring in this repo:

- All outbound API calls must use shared functions from `demos/utility/`, not inline curl.
- New CLI dependencies need an installer in `compute_init/`.
- Dynamic files must use `.tmpl.*` templates resolved by `resolve_template`.
- Each demo uses a single `setup/vars.env` for configuration.
- YAML must never be generated via heredoc -- use template files.
- MCP references must stay under `mcp-server/`; demo docs must not mention MCP.

Full rules: see comments in `index.js` and the `GLOBAL_CONTRACT` / `DOMAIN_RULES` sections that were consolidated into this file.

## Changelog

- **1.3.0** -- Added `validate_readme` tool and documentation guidelines enforcement.
- **1.2.0** -- Added `provision_workload` tool (API key auth, credential file generation).
- **1.1.0** -- Added `provision_safe` and `create_demo_safe` tools.
- **1.0.0** -- Initial release with `create_demo` tool.

## Troubleshooting

| Problem | Fix |
|---------|-----|
| Server not loading | Verify `node -v` is 18+, config path is absolute, client was restarted |
| "Failed to get identity token" | Check `demos/tenant_vars.sh` credentials and network connectivity |
| "Demo path does not exist" | Create the demo first with `create_demo` |
| "Safe already exists" | Use a different name or delete the existing safe in Privilege Cloud UI |
| "CYBR_DEMOS_PATH: unbound variable" | Export the variable in your shell profile |

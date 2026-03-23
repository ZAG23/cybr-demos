# cybr-demos

Runnable demos for [CyberArk](https://www.cyberark.com/) **Secrets Manager**, **Secrets Hub**, and **Credential Providers** on Linux, Kubernetes, CI platforms, and Windows.

## Quick start

1. Point **`CYBR_DEMOS_PATH`** at the root of this repository.
2. Edit **`demos/tenant_vars.sh`** (tenant, service account, and optional `LAB_ID`).
3. Open a scenario under **`demos/`** and follow that folder’s `README.md`, `setup.sh`, and `demo.sh` / `demo.ps1`.

## Where to read next

| Topic | Location |
|--------|-----------|
| How to write demo docs | [`AGENTS.md`](AGENTS.md), [`demos/demo_md_guidelines.md`](demos/demo_md_guidelines.md) |
| MCP / lab automation docs | [`mcp-server/README.md`](mcp-server/README.md) |
| Ubuntu / Windows VM setup | [`compute_init/ubuntu/setup.sh`](compute_init/ubuntu/setup.sh), [`compute_init/windows/setup.ps1`](compute_init/windows/setup.ps1) |
| One-shot clone + Ubuntu init | [`init_cybr_demos.sh`](init_cybr_demos.sh) |
| Bash lint (local + CI on `main`) | [`.shellcheckrc`](.shellcheckrc), [`.github/workflows/shellcheck.yml`](.github/workflows/shellcheck.yml) |

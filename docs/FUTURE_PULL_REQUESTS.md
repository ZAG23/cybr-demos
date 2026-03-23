# Planned contributions to `David-Lang/cybr-demos`

Local working list for this fork (kept on branch **`edit`** only). **Do not open or update pull requests on David’s repo without explicit approval.**

## Open upstream PRs (fork head branches)

Keep these remote branches on `origin` until David merges or you close the PR:

| PR | Branch on fork | Title |
|----|----------------|--------|
| [#12](https://github.com/David-Lang/cybr-demos/pull/12) | `zach/layer-on-upstream` | Shellcheck fixes |
| [#13](https://github.com/David-Lang/cybr-demos/pull/13) | `docs/onboarding-readme` | Onboarding README |

After both are merged (or closed), delete the remote branches:

```bash
git push origin --delete zach/layer-on-upstream docs/onboarding-readme
```

## Branch layout (this fork)

- **`main`** — tracks **`upstream/main`** (David’s latest `main`). Reset/rebase from upstream when you pull his changes.
- **`edit`** — your single private working branch (this file, experiments, WIP). Rebase onto `main` as needed.

## Future PRs (backlog — one at a time)

1. **Secrets Hub READMEs** — `demos/secrets_hub/asm/README.md`, `hashi_vault/README.md` (short intros; align with `AGENTS.md`).
2. **Kubernetes docs merge** — Fold useful narrative into `demo_setup.md` / `demo_validation.md` under `demos/secrets_manager/k8s/`.
3. **CI (ask David)** — `.github/workflows` shellcheck / secret-scan from fork history if desired.
4. **AI guidance** — Reconcile `CLAUDE.md` with `.aiassistant/rules/project_rules.md`.
5. **iPhone CP demo** — `origin` history: branch `claude/iphone-terminal-access-sngU1` (recover from reflog or backup before deleting old branches if still needed).

## Recovering deleted fork branches

If you removed a branch that still had unique commits, use **`git reflog`** locally or GitHub’s **closed branch / commit SHA** from the web UI before the branch was deleted.

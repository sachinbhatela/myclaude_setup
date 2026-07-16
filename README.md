# myclaude_setup

Replicate my Claude Code environment (plugins, MCP servers, agents/skills, settings) on
any machine. **Config only — no project/ADIB code.**

## Quickstart

```bash
git clone https://github.com/<you>/myclaude_setup.git
cd myclaude_setup

# Windows
powershell -ExecutionPolicy Bypass -File bootstrap.ps1

# macOS / Linux
bash bootstrap.sh
```

Then **relaunch Claude Code** — it installs the enabled plugins on next launch.

## What it does
1. Merges `claude-settings.snippet.json` into `~/.claude/settings.json` (non-destructive,
   backs up first) — 6 plugin marketplaces + 29 enabled plugins + baseline model/effort.
2. Installs `uv` + **serena** (code-intelligence MCP) and registers it as a user MCP.
3. Prints the remaining manual steps.

## What it does NOT do (manual — see `ONBOARDING.md`)
- **claude.ai connector MCPs** (Microsoft Learn, etc.) — account-scoped; enable in
  claude.ai → Settings → Connectors on your subscription.
- **Azure toolchain** (`az`, Terraform) + `az login` — only if you do Azure/IaC work.
  Note the **MFA / WAM-broker gotcha** documented in `ONBOARDING.md §3`.
- **gh CLI** — optional; zip fallback in `ONBOARDING.md §5`.

## Files
| File | Purpose |
|---|---|
| `bootstrap.ps1` / `bootstrap.sh` | one-shot setup |
| `apply_config.py` | non-destructive settings.json merge (idempotent) |
| `claude-settings.snippet.json` | marketplaces + enabled plugins (source of truth) |
| `ONBOARDING.md` | full reference: every tool, MCP, auth, and gotcha |

## Notes
- Plugins/MCP/skills/agents live in `~/.claude` — machine + OS-user local, **not** tied to
  your Claude subscription. Switching Claude accounts keeps them; only claude.ai connectors
  are per-account.
- `caveman` + `ponytail` auto-activate via SessionStart hooks (terse-prose + lazy-code
  styles). Toggle with `/caveman` and `/ponytail`, or "normal mode".
- Re-running `bootstrap` is safe (idempotent).

# Scope & Usage — what's global, what's automatic, how to use it

How the pieces from this setup are **scoped** (global vs project vs account) and **invoked**
(automatic vs manual), so you know what you get, where, and how to trigger it correctly.

---

## 1. Scope — where each thing lives

| Thing | Scope | Location | Travels to a new folder? | Survives Claude-account switch? |
|---|---|---|---|---|
| **Plugins** (all 29) | **Global** (machine + OS user) | `~/.claude/plugins/` | ✅ yes | ✅ yes |
| **Skills** (from plugins) | **Global** | inside plugins | ✅ yes | ✅ yes |
| **Agents** (subagents) | **Global** | inside plugins | ✅ yes | ✅ yes |
| **Hooks** (caveman/ponytail SessionStart, etc.) | **Global** | `~/.claude/settings.json` | ✅ yes | ✅ yes |
| **Plugin MCP servers** (azure, context7, figma, hf, obsidian, postman, vercel) | **Global** | inside plugins | ✅ yes | ✅ yes |
| **serena MCP** | **Global** (user-scoped) | `~/.claude.json` `mcpServers` | ✅ yes | ✅ yes |
| **Permissions / model / effort** | **Global** | `~/.claude/settings.json` | ✅ yes | ✅ yes |
| **claude.ai connectors** (Microsoft Learn, Atlassian, Notion…) | **Account** | claude.ai → Connectors | ✅ (same account) | ❌ per-account — re-enable |
| **`CLAUDE.md`** (project rules) | **Project** | repo root | ❌ per-repo | n/a |
| **`.claude/settings.json`** (project overrides) | **Project** | repo `.claude/` | ❌ per-repo | n/a |
| **Terraform state / git / tool auth caches** | Project / machine | repo dir / OS | ❌ / ✅ | n/a |

**Rule of thumb:** *tooling* (plugins, MCP, skills, agents, hooks) is **global** — install once
per machine, works everywhere. *Rules & state* (`CLAUDE.md`, TF state) are **per-project**.
*Connectors* are **per Claude account**.

**Global vs project precedence:** a project `.claude/settings.json` overrides the global
`~/.claude/settings.json` for sessions launched from that directory (e.g. a per-project
`OBSIDIAN_VAULT_PATH`). Global applies everywhere else.

---

## 2. Invocation — is it used automatically?

| Capability | Auto-used when needed? | How it triggers |
|---|---|---|
| **Hooks** (caveman, ponytail) | ✅ **Always, automatic** | Fire on the event (SessionStart, PostToolUse…) every session — zero action. You'll see them announce at start. |
| **Skills** | ✅ **Auto when relevant** (+ manual) | Claude reads each skill's "when to use" description and invokes it when your task matches. You can also force one with `/skill-name`. |
| **Agents** (subagents) | ✅ **Auto when task fits** (+ manual) | Claude spawns the matching agent for suitable work (e.g. a code-review agent on "review this"). You can also request one explicitly. |
| **MCP tools** (serena, azure, context7, Microsoft Learn…) | ✅ **Auto when needed** | Claude calls the tool when the task needs it (docs lookup → Microsoft Learn/context7; code nav → serena; Azure ops → azure MCP). Tool schemas load on demand. |
| **Plugins** | container | They just *deliver* the skills/agents/hooks/MCP above — being "enabled" is what makes those available. |
| **claude.ai connectors** | ✅ **once enabled** | Enable in claude.ai UI once; then Claude uses them automatically like any MCP. |

**Bottom line:** you don't manually wire skills/agents/MCP per task — **describe your task
naturally and Claude auto-selects the right capability.** Slash commands are an override, not
a requirement. Hooks are the only always-on layer.

---

## 3. How to use correctly

### Just work — auto-invocation
Describe the task in plain language. Examples of what auto-fires:
- "review this diff" → code-review / coderabbit skill or agent
- "how do I use <library>" → context7 (live docs) or Microsoft Learn (MS/Azure)
- "find where X is defined / rename symbol" → serena MCP
- "deploy this to Vercel" / "build a Figma-to-code component" → vercel / figma
- "debug this failure" → superpowers systematic-debugging

### Force a skill / command
Type `/` to see available slash commands, e.g. `/code-review`, `/obsidian-save`,
`/playground`, `/caveman`, `/ponytail`.

### Behavior styles (always on via hooks)
- **caveman** — terse prose. `/caveman lite|full|ultra`; turn off with "normal mode" / "stop caveman".
- **ponytail** — lazy/minimal code discipline. `/ponytail lite|full|ultra`; "stop ponytail".

### MCP connectors (per account, one-time)
claude.ai → Settings → Connectors → enable (e.g. **Microsoft Learn**). After that it's automatic.

### Opt-in for heavy modes
Some capabilities are **not** auto (they cost a lot): multi-agent **workflows** and
**ultracode** run only when you explicitly ask ("use a workflow", "ultracode"). Normal skills
and single subagents are auto.

---

## 4. Machine vs subscription (recap)

- New **folder / project** → all global tooling already available; optionally add `CLAUDE.md`.
- New **Claude account, same machine** → tooling stays (it's in `~/.claude`); only re-enable
  claude.ai **connectors** on the new account.
- New **machine** → run this repo's `bootstrap` (see `README.md`), then enable connectors +
  (optionally) install `az`/Terraform.

See `README.md` for setup and `ONBOARDING.md` for the full tool/auth reference.

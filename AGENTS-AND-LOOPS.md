# Agents & Loops — task automation for devs and content creators

This repo ships a few **ready-made agents** and shows how to run **loops** (recurring/
self-paced tasks) and **scheduled agents**. If a capability you need isn't bundled, the last
section is the **add-on install guide** — how to pull in more agents, skills, plugins, or MCP.

---

## 1. Bundled agents (`agents/`)

Drop-in subagents — the bootstrap copies them to `~/.claude/agents/` (global), or you can put
them in a project's `.claude/agents/`. Claude picks the right one automatically when your task
matches its `description`, or you can call one explicitly ("use the content-researcher agent…").

| Agent | Audience | Does |
|---|---|---|
| **dev-code-reviewer** | dev | Reviews a diff/PR/file for correctness, security, missing tests. Read-only, ranked findings. |
| **dev-test-author** | dev | Writes focused tests for existing code, matching your framework; runs them. |
| **content-writer** | creator | Drafts/edits blog posts, docs, newsletters, copy in a specified voice; cites facts. |
| **content-researcher** | creator | Researches a topic → cited brief (facts, timeline, players, contrarian views, open questions). |

Use them:
```
"review this diff"                         -> dev-code-reviewer
"write tests for src/auth.py"              -> dev-test-author
"draft a launch post about <feature>"      -> content-writer
"research <topic> and give me a brief"     -> content-researcher
```

---

## 2. How agents work + how to install your own

**What an agent is:** a markdown file with frontmatter (`name`, `description`, optional
`tools`, `model`) + a system prompt. Claude runs it as an isolated subagent — its own context,
its own tool set — and you get back just the result.

**Where they live (scope):**
- **Global:** `~/.claude/agents/<name>.md` → available in every project.
- **Project:** `<repo>/.claude/agents/<name>.md` → only that repo (overrides global on name clash).

**Install a bundled or new agent:**
```bash
# global (all projects)
mkdir -p ~/.claude/agents && cp agents/*.md ~/.claude/agents/     # bootstrap does this
# or project-scoped
mkdir -p .claude/agents && cp agents/dev-code-reviewer.md .claude/agents/
```

**Create your own** — copy an existing file and edit:
```markdown
---
name: my-agent
description: When to use it (be specific — this is how Claude auto-selects it).
tools: Read, Grep, Glob, Edit, Write, Bash   # omit to inherit all tools
model: sonnet                                 # optional
---
System prompt: role, method, output format, guardrails.
```
Tips: make `description` trigger-rich (Claude matches tasks against it); give the least tools
the job needs; state the output format explicitly. Or generate one interactively with the
**plugin-dev** `agent-creator` agent ("create an agent that …").

---

## 3. Loops — recurring or self-paced tasks (`/loop`)

`/loop` re-runs a prompt or slash command on an interval (or self-paced if you omit the
interval). Great for babysitting long jobs or steady content cadences.

```
/loop 10m check CI on the current PR and summarize any failures
/loop 30m poll the deploy and tell me when it's live or broken
/loop /babysit-prs                 # self-paced: Claude decides when to re-run
```
Content-creator examples:
```
/loop 1d research trending topics in <niche> and draft 3 post ideas with hooks
/loop 4h scan <subreddit/X topic> for questions I could answer in a post
```
Stop a loop by telling Claude to stop it. Loops run in *this* session/agent.

---

## 4. Scheduled agents — background cron (`/schedule`)

For tasks that should run when you're away, `/schedule` creates cloud agents on a cron.
```
/schedule daily 8:00 AM  - summarize overnight PR activity and failing checks
/schedule every Friday 5pm - draft a weekly newsletter from this week's commits + notes
/schedule list           # see scheduled agents
/schedule remove <name>
```
Difference vs `/loop`: `/loop` runs in your current session; `/schedule` runs autonomously in
the background on a fixed cron and reports back.

---

## 5. Add-on install guide — pull in more when it's not bundled

If a needed agent/skill/plugin/MCP isn't here, install it as an add-on. How, by type:

### A new plugin (bundle of skills/agents/hooks/MCP)
```
/plugin marketplace add <owner>/<repo>       # register the marketplace
/plugin install <plugin>@<marketplace>       # enable it
```
Or add it declaratively to `~/.claude/settings.json` (`extraKnownMarketplaces` +
`enabledPlugins`) — same pattern as `claude-settings.snippet.json` in this repo — and relaunch.

### A standalone skill (single capability)
Place it at `~/.claude/skills/<name>/SKILL.md` (global) or `<repo>/.claude/skills/<name>/SKILL.md`
(project). It auto-loads; invoke with `/<name>` or let Claude pick it up. Scaffold one with the
**skill-development** / plugin-dev skills.

### A standalone agent
Drop the `.md` in `~/.claude/agents/` (global) or `<repo>/.claude/agents/` (project). See §2.

### A new MCP server
```
claude mcp add <name> --scope user -- <command> <args...>     # e.g. serena in bootstrap
```
User scope = all projects; project scope = `--scope project` (writes repo `.mcp.json`).
claude.ai connector MCPs (Microsoft Learn etc.) are enabled in claude.ai → Connectors instead.

### A loop or schedule
Nothing to install — `/loop` and `/schedule` are always available (see §3–4).

**Rule of thumb:** *bundled here* = works after `bootstrap` + relaunch. *Add-on* = one of the
commands above, then relaunch if it's a plugin. Global install (`~/.claude`) makes it available
everywhere; project install (`<repo>/.claude`) scopes it to one repo.

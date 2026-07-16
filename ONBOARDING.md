# ONBOARDING — Replicate this Claude Code + Azure/Terraform setup

Goal: bring a **new machine + new Claude subscription** to the same working state — all
Claude Code plugins, MCP servers, agents/skills, plus the Azure/Terraform toolchain.

> Everything Claude-Code lives in `~/.claude` (per OS user), **not** in the Claude
> subscription. Plugins/MCP/hooks are machine-local; only claude.ai *connectors*
> (e.g. Microsoft Learn) are account-scoped and set up in the claude.ai UI.

---

## 0. Prerequisites (install first)

| Tool | Why | Install (Windows) |
|---|---|---|
| **Claude Code CLI** | the agent | per Anthropic docs (`claude` on PATH) |
| **git** | repo | winget install Git.Git |
| **Azure CLI** (`az`) | all Azure ops | winget install Microsoft.AzureCLI |
| **Terraform** ≥1.6,<2.0 | IaC | winget install Hashicorp.Terraform |
| **Python** 3.10+ + **openpyxl** | inventory xlsx, scripts | winget install Python.Python.3.12 ; `pip install openpyxl` |
| **uv** | serena + obsidian/hf research tools | `powershell -c "irm https://astral.sh/uv/install.ps1 | iex"` |
| **Node.js / npx** | `ruflo` project MCP | winget install OpenJS.NodeJS.LTS |
| **GitHub CLI** (`gh`) | PR status (optional) | see §5 (winget may fail on Windows Server — zip fallback) |

macOS/Linux: swap `winget` for `brew`/apt equivalents.

---

## 1. Claude Code plugins — marketplaces + enabled plugins

### Fastest path: merge into `~/.claude/settings.json`
Add these two blocks (Claude Code installs them on next launch):

```jsonc
{
  "extraKnownMarketplaces": {
    "claude-plugins-official": { "source": { "source": "github", "repo": "anthropics/claude-plugins-public" } },
    "ui-ux-pro-max-skill":     { "source": { "source": "github", "repo": "nextlevelbuilder/ui-ux-pro-max-skill" } },
    "obsidian-second-brain":   { "source": { "source": "github", "repo": "eugeniughelbur/obsidian-second-brain" } },
    "ponytail":                { "source": { "source": "github", "repo": "DietrichGebert/ponytail" } },
    "caveman":                 { "source": { "source": "github", "repo": "JuliusBrussee/caveman" } },
    "google-labs-code-stitch-skills": { "source": { "source": "github", "repo": "google-labs-code/stitch-skills" } }
  },
  "enabledPlugins": {
    "superpowers@claude-plugins-official": true,
    "code-review@claude-plugins-official": true,
    "claude-md-management@claude-plugins-official": true,
    "claude-code-setup@claude-plugins-official": true,
    "playground@claude-plugins-official": true,
    "motion@claude-plugins-official": true,
    "azure@claude-plugins-official": true,
    "terraform@claude-plugins-official": true,
    "frontend-design@claude-plugins-official": true,
    "context7@claude-plugins-official": true,
    "code-simplifier@claude-plugins-official": true,
    "vercel@claude-plugins-official": true,
    "figma@claude-plugins-official": true,
    "plugin-dev@claude-plugins-official": true,
    "hookify@claude-plugins-official": true,
    "rust-analyzer-lsp@claude-plugins-official": true,
    "huggingface-skills@claude-plugins-official": true,
    "coderabbit@claude-plugins-official": true,
    "mcp-server-dev@claude-plugins-official": true,
    "postman@claude-plugins-official": true,
    "atomic-agents@claude-plugins-official": true,
    "qodo-skills@claude-plugins-official": true,
    "ui-ux-pro-max@ui-ux-pro-max-skill": true,
    "obsidian-second-brain@obsidian-second-brain": true,
    "ponytail@ponytail": true,
    "caveman@caveman": true,
    "stitch-build@google-labs-code-stitch-skills": true,
    "stitch-design@google-labs-code-stitch-skills": true,
    "stitch-utilities@google-labs-code-stitch-skills": true
  }
}
```
Also set (optional, matches this setup):
```jsonc
{ "model": "opus[1m]", "effortLevel": "xhigh", "permissions": { "defaultMode": "auto" }, "autoUpdatesChannel": "latest" }
```
Then relaunch Claude Code. Plugin **MCP servers** (azure, context7, figma, huggingface,
obsidian, postman, vercel) and **agents/skills** ship inside these plugins — no extra step.

### Manual path (in a Claude Code session), equivalent:
```
/plugin marketplace add anthropics/claude-plugins-public
/plugin marketplace add nextlevelbuilder/ui-ux-pro-max-skill
/plugin marketplace add eugeniughelbur/obsidian-second-brain
/plugin marketplace add DietrichGebert/ponytail
/plugin marketplace add JuliusBrussee/caveman
/plugin marketplace add google-labs-code/stitch-skills
/plugin install caveman@caveman
/plugin install ponytail@ponytail
/plugin install azure@claude-plugins-official
/plugin install terraform@claude-plugins-official
# ...repeat for each plugin in enabledPlugins above
```

**Caveman + Ponytail** auto-activate via SessionStart hooks the plugins register — you'll
see `CAVEMAN MODE ACTIVE` / `PONYTAIL MODE ACTIVE` at session start. Toggle with
`/caveman lite|full|ultra` and `/ponytail lite|full|ultra` (or "stop caveman"/"normal mode").

---

## 2. MCP servers

### serena (user-level, code intelligence)
Install the tool, then add to `~/.claude.json` `mcpServers`:
```bash
uv tool install git+https://github.com/oraios/serena    # provides serena(.exe) on PATH / ~/.local/bin
```
```jsonc
// ~/.claude.json  ->  "mcpServers": { ... }
"serena": {
  "type": "stdio",
  "command": "serena",              // or full path e.g. C:/Users/<you>/.local/bin/serena.exe
  "args": ["start-mcp-server", "--context", "claude-code", "--project-from-cwd"],
  "env": {}
}
```

### ruflo (project-level MCP — only for the ADIB parent folder)
Scoped under that project in `~/.claude.json`; runs via npx:
```jsonc
"ruflo": { "type": "stdio", "command": "npx", "args": ["ruflo@latest", "mcp", "start"], "env": {} }
```

### claude.ai connector MCPs (account-scoped — set up in the new subscription)
These belong to the Claude account, NOT the machine. On the new subscription, open
**claude.ai → Settings → Connectors** and enable/authenticate the ones you use:
- **Microsoft Learn** (used here for grounded Azure docs) — no auth
- Optional: Atlassian Rovo, Notion, Figma, Microsoft 365, Vercel, Adobe, ThousandEyes (OAuth each)

---

## 3. Azure authentication (has a known gotcha)

```bash
az login --tenant <TENANT_ID> --use-device-code
```
**If `terraform plan` fails with `AADSTS50076 ... multi-factor authentication ... 00000003-...` (Microsoft Graph):**
conditional-access requires MFA for Graph and the Windows WAM broker caches a non-MFA
session. Fix:
```bash
az config set core.enable_broker_on_windows=false
az logout ; az account clear
az login --tenant <TENANT_ID> --scope https://graph.microsoft.com/.default --use-device-code   # COMPLETE the MFA prompt
az account get-access-token --resource https://graph.microsoft.com --query expiresOn -o tsv     # must succeed, not AADSTS50076
```
Fallback: run Terraform as a service principal (`ARM_CLIENT_ID/ARM_CLIENT_SECRET/ARM_TENANT_ID/ARM_SUBSCRIPTION_ID`) — SP tokens bypass user MFA.

---

## 4. This project (Terraform)

```bash
git clone https://github.com/sachinbhatela/adib-pfm-poc.git
cd adib-pfm-poc/terraform
# terraform.tfvars is committed (POC). Review subscription_id/tenant_id + toggles.
terraform init
terraform plan          # expect 0 destroy on a clean tree (moved{} blocks are no-ops)
```
- Region **uaenorth**; API Center exception in **swedencentral**.
- Providers pinned in `versions.tf` (azurerm ~>4.79, azapi ~>2.10, random, tls, http); lockfile committed.
- Per-service toggles live in `terraform.tfvars` (`<svc>_enabled`). Foundation (networking,
  monitor, keyvault, appinsights) is always-on. Full service map: `ADIB-PFM-POC-Deployment-Inventory.xlsx`.
- API Center RP must be registered once: `az provider register -n Microsoft.ApiCenter`.
- Project rules the agent follows live in `CLAUDE.md` — read it.

---

## 5. GitHub CLI (optional, for PR status)

`winget` can fail on Windows Server (`file cannot be accessed by the system`). Zip fallback:
```powershell
$dest="$HOME\gh"; mkdir $dest -Force
$tag=(irm https://api.github.com/repos/cli/cli/releases/latest).tag_name.TrimStart('v')
irm "https://github.com/cli/cli/releases/download/v$tag/gh_${tag}_windows_amd64.zip" -OutFile "$dest\gh.zip"
Expand-Archive "$dest\gh.zip" $dest -Force
[Environment]::SetEnvironmentVariable("PATH", (([Environment]::GetEnvironmentVariable("PATH","User"))+";$dest\bin"), "User")
gh auth login   # interactive
```
Push access here uses the git Windows credential helper — `gh` login is not required for `git push`.

---

## 6. Verify

```bash
# in a Claude Code session, new folder:
/caveman            # shows mode -> confirms caveman plugin loaded
/ponytail           # confirms ponytail loaded
# MCP: ask a question that triggers Microsoft Learn or serena
az account show                         # Azure auth
terraform -chdir=terraform validate     # config valid
```

Checklist: caveman/ponytail auto-activate ✅ · plugins listed in `/plugin` ✅ · serena +
Microsoft Learn MCP respond ✅ · `az`/`terraform` work ✅ · `terraform plan` = 0 destroy ✅.

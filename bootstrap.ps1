# Bootstrap Claude Code setup on a new Windows machine.
# Clone this repo, then:  powershell -ExecutionPolicy Bypass -File bootstrap.ps1
# Idempotent. Does NOT touch Azure/ADIB code - Claude Code config only.

$ErrorActionPreference = "Stop"
$here = Split-Path -Parent $MyInvocation.MyCommand.Path

Write-Host "== 1. Merge plugin/marketplace config into ~/.claude/settings.json ==" -ForegroundColor Cyan
if (-not (Get-Command python -ErrorAction SilentlyContinue)) {
  Write-Warning "python not found - install Python 3.10+ first (winget install Python.Python.3.12)."
} else {
  python "$here\apply_config.py"
}

Write-Host "`n== 2. Install uv + serena (code-intelligence MCP) ==" -ForegroundColor Cyan
if (-not (Get-Command uv -ErrorAction SilentlyContinue)) {
  Write-Host "installing uv..."
  powershell -c "irm https://astral.sh/uv/install.ps1 | iex"
}
$env:PATH = "$env:USERPROFILE\.local\bin;$env:PATH"
try {
  uv tool install "git+https://github.com/oraios/serena"
  Write-Host "serena installed"
} catch {
  Write-Warning "serena install failed: $($_.Exception.Message)"
}

Write-Host "`n== 3. Register serena as a user-scoped MCP server ==" -ForegroundColor Cyan
if (Get-Command claude -ErrorAction SilentlyContinue) {
  try {
    claude mcp add serena --scope user -- serena start-mcp-server --context claude-code --project-from-cwd
    Write-Host "serena MCP registered"
  } catch {
    Write-Warning "'claude mcp add' failed - add serena manually (see ONBOARDING.md section 2)."
  }
} else {
  Write-Warning "'claude' CLI not on PATH - install Claude Code, then run: claude mcp add serena --scope user -- serena start-mcp-server --context claude-code --project-from-cwd"
}

Write-Host "`n== 4. Install bundled agents to ~/.claude/agents ==" -ForegroundColor Cyan
$agentsSrc = Join-Path $here "agents"
if (Test-Path $agentsSrc) {
  $agentsDst = Join-Path $env:USERPROFILE ".claude\agents"
  New-Item -ItemType Directory -Force -Path $agentsDst | Out-Null
  Copy-Item "$agentsSrc\*.md" $agentsDst -Force
  Write-Host ("copied: " + ((Get-ChildItem "$agentsSrc\*.md").Name -join ', '))
} else {
  Write-Host "no agents/ folder - skipping"
}

Write-Host "`n== DONE. Manual steps left (see ONBOARDING.md) ==" -ForegroundColor Green
Write-Host " - Relaunch Claude Code (installs the enabled plugins)."
Write-Host " - claude.ai -> Settings -> Connectors: enable Microsoft Learn (+ any others)."
Write-Host " - Install az CLI + Terraform if working on Azure/IaC (see ONBOARDING.md)."
Write-Host " - az login (note the MFA/WAM-broker gotcha in ONBOARDING.md)."

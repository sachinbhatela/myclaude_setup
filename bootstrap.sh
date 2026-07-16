#!/usr/bin/env bash
# Bootstrap Claude Code setup on a new macOS/Linux machine.
# Clone this repo, then:  bash bootstrap.sh
# Idempotent. Claude Code config only - no Azure/ADIB code.
set -euo pipefail
HERE="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

echo "== 1. Merge plugin/marketplace config into ~/.claude/settings.json =="
if command -v python3 >/dev/null 2>&1; then python3 "$HERE/apply_config.py"
elif command -v python >/dev/null 2>&1; then python "$HERE/apply_config.py"
else echo "WARN: python not found - install Python 3.10+ first."; fi

echo
echo "== 2. Install uv + serena (code-intelligence MCP) =="
if ! command -v uv >/dev/null 2>&1; then
  curl -LsSf https://astral.sh/uv/install.sh | sh
fi
export PATH="$HOME/.local/bin:$PATH"
uv tool install "git+https://github.com/oraios/serena" || echo "WARN: serena install failed"

echo
echo "== 3. Register serena as a user-scoped MCP server =="
if command -v claude >/dev/null 2>&1; then
  claude mcp add serena --scope user -- serena start-mcp-server --context claude-code --project-from-cwd \
    || echo "WARN: 'claude mcp add' failed - add serena manually (ONBOARDING.md section 2)."
else
  echo "WARN: 'claude' CLI not found - after installing Claude Code run:"
  echo "  claude mcp add serena --scope user -- serena start-mcp-server --context claude-code --project-from-cwd"
fi

echo
echo "== 4. Install bundled agents to ~/.claude/agents =="
if [ -d "$HERE/agents" ]; then
  mkdir -p "$HOME/.claude/agents"
  cp "$HERE"/agents/*.md "$HOME/.claude/agents/" && echo "copied bundled agents"
else
  echo "no agents/ folder - skipping"
fi

echo
echo "== DONE. Manual steps left (see ONBOARDING.md) =="
echo " - Relaunch Claude Code (installs the enabled plugins)."
echo " - claude.ai -> Settings -> Connectors: enable Microsoft Learn (+ others)."
echo " - Install az CLI + Terraform for Azure/IaC work (see ONBOARDING.md)."
echo " - az login (mind the MFA/WAM-broker gotcha in ONBOARDING.md)."

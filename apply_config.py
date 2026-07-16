#!/usr/bin/env python3
"""Merge claude-settings.snippet.json into ~/.claude/settings.json (non-destructive).

Adds our marketplaces + enabledPlugins + baseline settings without clobbering any
existing keys. Backs up settings.json first. Idempotent — safe to re-run.

Usage:  python apply_config.py [--dry-run]
"""
import json, os, sys, shutil, time

HERE = os.path.dirname(os.path.abspath(__file__))
SNIPPET = os.path.join(HERE, "claude-settings.snippet.json")
CLAUDE_DIR = os.path.join(os.path.expanduser("~"), ".claude")
SETTINGS = os.path.join(CLAUDE_DIR, "settings.json")
DRY = "--dry-run" in sys.argv


def load(path, default):
    if os.path.exists(path):
        with open(path, encoding="utf-8") as f:
            return json.load(f)
    return default


def main():
    snippet = load(SNIPPET, {})
    os.makedirs(CLAUDE_DIR, exist_ok=True)
    settings = load(SETTINGS, {})

    added_mp, added_pl = [], []

    # merge marketplaces (add missing)
    mp = settings.setdefault("extraKnownMarketplaces", {})
    for k, v in snippet.get("extraKnownMarketplaces", {}).items():
        if k not in mp:
            mp[k] = v
            added_mp.append(k)

    # merge enabled plugins (add missing)
    pl = settings.setdefault("enabledPlugins", {})
    for k, v in snippet.get("enabledPlugins", {}).items():
        if k not in pl:
            pl[k] = v
            added_pl.append(k)

    # baseline scalars only if absent (don't override user choices)
    for k in ("model", "effortLevel", "autoUpdatesChannel"):
        if k in snippet and k not in settings:
            settings[k] = snippet[k]
    if "permissions" not in settings and "permissions" in snippet:
        settings["permissions"] = snippet["permissions"]

    print(f"marketplaces added: {added_mp or 'none (already present)'}")
    print(f"plugins added:      {len(added_pl)} -> {added_pl or 'none (already present)'}")

    if DRY:
        print("[dry-run] not writing.")
        return

    if os.path.exists(SETTINGS):
        bak = SETTINGS + f".bak.{int(time.time())}"
        shutil.copy2(SETTINGS, bak)
        print(f"backup: {bak}")
    with open(SETTINGS, "w", encoding="utf-8") as f:
        json.dump(settings, f, indent=2)
    print(f"wrote:  {SETTINGS}")
    print("Relaunch Claude Code — it installs the enabled plugins on next launch.")


if __name__ == "__main__":
    main()

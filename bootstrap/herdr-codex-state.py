#!/usr/bin/env python3
"""Read-only inspection of Herdr's multi-file Codex integration."""

import argparse
import json
import os
from pathlib import Path
import shlex
import sys

if sys.version_info < (3, 11):
    print("Herdr Codex integration requires Python 3.11 or newer", file=sys.stderr)
    sys.exit(2)

import tomllib


def reject_json_constant(_value: str) -> None:
    # Herdr's JSON parser does not accept Python's NaN/Infinity extensions.
    raise ValueError("non-JSON numeric constant")


def inspect(home: Path) -> dict[str, str]:
    home = Path(os.path.abspath(home))

    def result(state: str, reason: str) -> dict[str, str]:
        return {"state": state, "reason": reason, "home": str(home)}

    if home.is_symlink() or (home.exists() and not home.is_dir()):
        return result("conflict", "Codex home must be a real directory")

    script = home / "herdr-agent-state.sh"
    config_path = home / "config.toml"
    hooks_path = home / "hooks.json"
    for file in (script, config_path, hooks_path):
        if file.is_symlink() or (file.exists() and not file.is_file()):
            return result("conflict", f"{file.name} must be a regular file, not a link or directory")

    try:
        config = tomllib.loads(config_path.read_text(encoding="utf-8")) if config_path.exists() else {}
    except (OSError, UnicodeError, tomllib.TOMLDecodeError):
        return result("conflict", "config.toml is unreadable or invalid TOML")
    features = config.get("features", {})
    if not isinstance(features, dict):
        return result("conflict", "config.toml features must be a table")
    if "hooks" in features and not isinstance(features["hooks"], bool):
        return result("conflict", "config.toml features.hooks must be a boolean")
    if features.get("hooks") is False:
        return result("conflict", "features.hooks is explicitly disabled; enable it intentionally before rerunning")

    try:
        hooks = json.loads(hooks_path.read_text(encoding="utf-8"), parse_constant=reject_json_constant) if hooks_path.exists() else {}
    except (OSError, UnicodeError, ValueError):
        return result("conflict", "hooks.json is unreadable or invalid JSON")
    if not isinstance(hooks, dict) or not isinstance(hooks.get("hooks", {}), dict):
        return result("conflict", "hooks.json must contain a hooks object")
    session_hooks = hooks.get("hooks", {}).get("SessionStart", [])
    if not isinstance(session_hooks, list):
        return result("conflict", "hooks.json SessionStart must be an array")

    registered = False
    for rule in session_hooks:
        if not isinstance(rule, dict) or not isinstance(rule.get("hooks"), list):
            return result("conflict", "hooks.json contains an invalid SessionStart rule")
        for hook in rule["hooks"]:
            if not isinstance(hook, dict):
                return result("conflict", "hooks.json contains an invalid SessionStart hook")
            if hook.get("type") != "command":
                continue
            command = hook.get("command")
            if not isinstance(command, str):
                return result("conflict", "hooks.json command hooks must have string commands")
            try:
                arguments = shlex.split(command)
            except ValueError:
                # Other hooks may use Bash syntax that shlex does not parse.
                continue
            if (
                arguments in (["bash", str(script), "session"], ["/bin/bash", str(script), "session"])
                and rule.get("matcher") in (None, "", "*")
            ):
                registered = True

    script_present = script.exists()
    if script_present:
        try:
            lines = script.read_text(encoding="utf-8").splitlines()
        except (OSError, UnicodeError):
            return result("conflict", "herdr-agent-state.sh is unreadable")
        if "# installed by herdr" not in lines or "# HERDR_INTEGRATION_ID=codex" not in lines:
            return result("conflict", "herdr-agent-state.sh is not a recognized Herdr-generated script")

    if script_present and registered and features.get("hooks") is True:
        return result("complete", "script, SessionStart registration, and enabled hooks are present")
    if script_present or registered:
        return result("partial", "Herdr script, SessionStart registration, or enabled hooks are missing")
    return result("missing", "Herdr Codex integration is not installed")


if __name__ == "__main__":
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("home", type=Path, help="effective Codex home (CODEX_HOME)")
    args = parser.parse_args()
    try:
        print(json.dumps(inspect(args.home)))
    except OSError:
        print("Cannot inspect Codex integration paths", file=sys.stderr)
        sys.exit(2)

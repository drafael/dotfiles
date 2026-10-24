#!/usr/bin/env python3
"""Read-only inspection of Herdr's Claude Code hook integration."""

import argparse
import json
import os
from pathlib import Path
import shlex
import sys

if sys.version_info < (3, 11):
    print("Herdr Claude integration requires Python 3.11 or newer", file=sys.stderr)
    sys.exit(2)


SESSION_MATCHER = "^(startup|resume|clear|compact|fork)$"


def reject_json_constant(_value: str) -> None:
    # Herdr's JSON parser does not accept Python's NaN/Infinity extensions.
    raise ValueError("non-JSON numeric constant")


def inspect(home: Path) -> dict[str, str]:
    home = Path(os.path.abspath(home))

    def result(state: str, reason: str) -> dict[str, str]:
        return {"state": state, "reason": reason, "home": str(home)}

    for directory in (home, home / "hooks"):
        if directory.is_symlink() or (directory.exists() and not directory.is_dir()):
            return result("conflict", f"{directory} must be a real directory")

    script = home / "hooks/herdr-agent-state.sh"
    settings_path = home / "settings.json"
    for file in (script, settings_path):
        if file.is_symlink() or (file.exists() and not file.is_file()):
            return result("conflict", f"{file.name} must be a regular file, not a link or directory")

    try:
        settings = json.loads(settings_path.read_text(encoding="utf-8"), parse_constant=reject_json_constant) if settings_path.exists() else {}
    except (OSError, UnicodeError, ValueError):
        return result("conflict", "settings.json is unreadable or invalid JSON")
    if not isinstance(settings, dict) or not isinstance(settings.get("hooks", {}), dict):
        return result("conflict", "settings.json must contain an object with an optional hooks object")
    if "disableAllHooks" in settings and not isinstance(settings["disableAllHooks"], bool):
        return result("conflict", "settings.json disableAllHooks must be a boolean")
    if settings.get("disableAllHooks") is True:
        return result("conflict", "disableAllHooks is explicitly enabled; review that choice before rerunning")

    session_hooks = settings.get("hooks", {}).get("SessionStart", [])
    if not isinstance(session_hooks, list):
        return result("conflict", "settings.json SessionStart must be an array")
    registered = False
    for rule in session_hooks:
        if not isinstance(rule, dict) or not isinstance(rule.get("hooks"), list):
            return result("conflict", "settings.json contains an invalid SessionStart rule")
        for hook in rule["hooks"]:
            if not isinstance(hook, dict):
                return result("conflict", "settings.json contains an invalid SessionStart hook")
            if hook.get("type") != "command":
                continue
            command = hook.get("command")
            if not isinstance(command, str):
                return result("conflict", "settings.json command hooks must have string commands")
            try:
                arguments = shlex.split(command)
            except ValueError:
                # Unrelated hooks may use Bash syntax that shlex does not parse.
                if str(script) in command:
                    return result("conflict", "unrecognized Herdr SessionStart command; review it manually")
                continue
            if str(script) not in arguments:
                continue
            if arguments not in (["bash", str(script), "session"], ["/bin/bash", str(script), "session"]):
                return result("conflict", "custom Herdr SessionStart command; review it manually")
            if rule.get("matcher") != SESSION_MATCHER:
                return result("conflict", "custom or legacy Herdr SessionStart matcher; review it manually")
            registered = True

    script_present = script.exists()
    if script_present:
        try:
            lines = script.read_text(encoding="utf-8").splitlines()
        except (OSError, UnicodeError):
            return result("conflict", "herdr-agent-state.sh is unreadable")
        if "# installed by herdr" not in lines or "# HERDR_INTEGRATION_ID=claude" not in lines:
            return result("conflict", "herdr-agent-state.sh is not a recognized Herdr-generated script")

    if script_present and registered:
        return result("complete", "script and SessionStart registration are present and hooks are not disabled")
    if script_present or registered:
        return result("partial", "Herdr script or SessionStart registration is missing")
    return result("missing", "Herdr Claude integration is not installed")


if __name__ == "__main__":
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("home", type=Path, help="effective Claude home (CLAUDE_CONFIG_DIR)")
    args = parser.parse_args()
    try:
        print(json.dumps(inspect(args.home)))
    except OSError:
        print("Cannot inspect Claude integration paths", file=sys.stderr)
        sys.exit(2)

#!/usr/bin/env python3
"""Read-only inspection of Herdr's GitHub Copilot CLI hook integration."""

import argparse
import json
import os
from pathlib import Path
import shlex
import sys

if sys.version_info < (3, 11):
    print("Herdr Copilot integration requires Python 3.11 or newer", file=sys.stderr)
    sys.exit(2)


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
    script_present = script.exists()
    native_command = "bash '" + str(script).replace("'", "'\"'\"'") + "'"
    registered = 0
    for hook in session_hooks:
        if not isinstance(hook, dict) or not isinstance(hook.get("type"), str):
            return result("conflict", "settings.json requires flat, typed SessionStart hooks")
        if hook["type"] != "command":
            continue
        if "bash" not in hook:
            # Copilot also supports PowerShell-only hooks; leave those alone.
            if not isinstance(hook.get("powershell"), str):
                return result("conflict", "settings.json command hooks require bash or powershell commands")
            continue
        command = hook["bash"]
        if not isinstance(command, str):
            return result("conflict", "settings.json bash hooks must have string commands")
        try:
            arguments = shlex.split(command)
        except ValueError:
            if str(script) in command:
                return result("conflict", "unrecognized Herdr SessionStart command; review it manually")
            continue
        # Native paths can retain redundant / or . components from COPILOT_HOME.
        if not any(Path(argument) == script for argument in arguments):
            continue
        if len(arguments) != 2 or arguments[0] not in ("bash", "/bin/bash") or Path(arguments[1]) != script:
            return result("conflict", "custom Herdr SessionStart command; review it manually")
        if hook.get("matcher") is not None:
            return result("conflict", "custom Herdr SessionStart matcher; review it manually")
        # Native merging compares command text, not shell-equivalent arguments.
        # Repairing another spelling would append a second active registration.
        if not script_present and command != native_command:
            return result("conflict", "non-native Herdr command spelling cannot be repaired safely; review it manually")
        registered += 1
    if registered > 1:
        return result("conflict", "multiple Herdr SessionStart hooks; resolve them manually")

    if script_present:
        try:
            lines = script.read_text(encoding="utf-8").splitlines()
        except (OSError, UnicodeError):
            return result("conflict", "herdr-agent-state.sh is unreadable")
        if "# installed by herdr" not in lines or "# HERDR_INTEGRATION_ID=copilot" not in lines:
            return result("conflict", "herdr-agent-state.sh is not a recognized Herdr-generated script")

    if script_present and registered:
        return result("complete", "script and flat SessionStart bash registration are present and hooks are not disabled")
    if script_present or registered:
        return result("partial", "Herdr script or SessionStart registration is missing")
    return result("missing", "Herdr Copilot integration is not installed")


if __name__ == "__main__":
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("home", type=Path, help="effective Copilot home (COPILOT_HOME)")
    args = parser.parse_args()
    try:
        print(json.dumps(inspect(args.home)))
    except OSError:
        print("Cannot inspect Copilot integration paths", file=sys.stderr)
        sys.exit(2)

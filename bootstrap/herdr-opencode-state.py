#!/usr/bin/env python3
"""Read-only inspection of Herdr's OpenCode server and TUI integrations."""

import argparse
import json
import os
from pathlib import Path
import re
import sys

if sys.version_info < (3, 11):
    print("Herdr OpenCode integration requires Python 3.11 or newer", file=sys.stderr)
    sys.exit(2)


GENERATED_FILES = {
    "plugins/herdr-agent-state.js": "opencode",
    "herdr-tui-session.js": "opencode-tui",
    "herdr-opencode/tui.js": "opencode-tui-v2",
}
CONFIG_FILES = {
    "tui.jsonc": ("plugin", "./herdr-tui-session.js"),
    "cli.json": ("plugins", "./herdr-opencode"),
}


def reject_json_constant(_value: str) -> None:
    raise ValueError("non-JSON numeric constant")


def parse_jsonc(text: str) -> object:
    # Preserve quoted strings while removing JSONC comments and trailing commas.
    string = r'"(?:[^"\\]|\\.)*"'
    text = re.sub(
        string + r"|//[^\r\n]*|/\*[\s\S]*?\*/",
        lambda match: match[0] if match[0].startswith('"') else " ",
        text,
    )
    tokens = re.findall(string + r"|\s+|.", text, flags=re.DOTALL)
    parts = []
    previous = ""
    for index, token in enumerate(tokens):
        if token == "," and previous not in ("", "[", "{", ",", ":"):
            following = index + 1
            while following < len(tokens) and tokens[following].isspace():
                following += 1
            if following < len(tokens) and tokens[following] in ("}", "]"):
                continue
        parts.append(token)
        if not token.isspace():
            previous = token
    return json.loads("".join(parts), parse_constant=reject_json_constant)


def inspect(home: Path, state_home: Path) -> dict[str, str]:
    home = Path(os.path.abspath(home))
    state_home = Path(os.path.abspath(state_home))

    def result(state: str, reason: str) -> dict[str, str]:
        return {"state": state, "reason": reason, "home": str(home), "state_home": str(state_home)}

    for directory in (home, home / "plugins", home / "herdr-opencode"):
        if directory.is_symlink() or (directory.exists() and not directory.is_dir()):
            return result("conflict", f"{directory} must be a real directory")
    for relative in (*GENERATED_FILES, *CONFIG_FILES):
        file = home / relative
        if file.is_symlink() or (file.exists() and not file.is_file()):
            return result("conflict", f"{relative} must be a regular file, not a link or directory")

    # OpenCode discovers both directory spellings and both JS/TS extensions.
    for relative in ("plugins/herdr-agent-state.ts", "plugin/herdr-agent-state.ts", "plugin/herdr-agent-state.js"):
        legacy = home / relative
        if legacy.exists() or legacy.is_symlink():
            return result("conflict", f"legacy Herdr plugin at {relative}; retire it manually to avoid duplicate loading")

    present = 0
    for relative, integration_id in GENERATED_FILES.items():
        file = home / relative
        if not file.exists():
            continue
        try:
            lines = file.read_text(encoding="utf-8").splitlines()
        except (OSError, UnicodeError):
            return result("conflict", f"{relative} is unreadable")
        if "// installed by herdr" not in lines or f"// HERDR_INTEGRATION_ID={integration_id}" not in lines:
            return result("conflict", f"{relative} is not a recognized Herdr-generated file")
        present += 1

    registered = set()
    # Herdr accepts a V1 registration in either file, but never writes tui.json:
    # OpenCode needs that file intact for its first V2 preference migration.
    config_files = {**CONFIG_FILES, "tui.json": ("plugin", "./herdr-tui-session.js")}
    for relative, (key, specifier) in config_files.items():
        file = home / relative
        if relative == "tui.json" and not file.is_file():
            continue
        try:
            config = parse_jsonc(file.read_text(encoding="utf-8")) if file.exists() else {}
        except (OSError, UnicodeError, ValueError):
            return result("conflict", f"{relative} is unreadable or invalid JSON/JSONC")
        if not isinstance(config, dict) or not isinstance(config.get(key, []), list):
            return result("conflict", f"{relative} must contain an object with an optional {key} array")
        found = False
        for entry in config.get(key, []):
            if isinstance(entry, str):
                reference = entry
            elif isinstance(entry, list) and len(entry) == 2 and isinstance(entry[0], str) and isinstance(entry[1], dict):
                reference = entry[0]
                if reference == specifier:
                    return result("conflict", f"custom Herdr plugin options in {relative}; review them manually")
            else:
                return result("conflict", f"{relative} contains an invalid plugin entry")
            if reference == specifier:
                found = True
            elif Path(reference.rstrip("/")).name == Path(specifier).name:
                return result("conflict", f"custom Herdr plugin reference in {relative}; review it manually")
        if found:
            registered.add(specifier)

    # Match Herdr's migration safeguard: do not require/create cli.json while
    # V1 preferences remain to be imported. An existing cli.json still needs its
    # V2 registration, even when the old preference files have been retained.
    cli_deferred = not (home / "cli.json").exists() and (
        (home / "tui.json").is_file() or (state_home / "opencode/kv.json").is_file()
    )
    if present == len(GENERATED_FILES) and "./herdr-tui-session.js" in registered and (
        "./herdr-opencode" in registered or cli_deferred
    ):
        if cli_deferred:
            return result("complete", "OpenCode V1 integration is complete; V2 registration awaits preference migration")
        return result("complete", "server plugin, TUI plugins, and both registrations are present")
    if present or registered:
        return result("partial", "a Herdr OpenCode plugin or registration is missing")
    return result("missing", "Herdr OpenCode integration is not installed")


if __name__ == "__main__":
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("home", type=Path, help="effective OpenCode configuration directory")
    parser.add_argument("state_home", type=Path, help="XDG state base, containing opencode/kv.json")
    args = parser.parse_args()
    try:
        print(json.dumps(inspect(args.home, args.state_home)))
    except OSError:
        print("Cannot inspect OpenCode integration paths", file=sys.stderr)
        sys.exit(2)

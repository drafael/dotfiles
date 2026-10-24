#!/bin/sh
set -eu

repository=$(CDPATH= cd -- "$(dirname -- "$0")/.." && pwd)
work=$(mktemp -d "${TMPDIR:-/tmp}/herdr-codex-bootstrap-test.XXXXXX")
trap 'rm -rf "$work"' EXIT HUP INT TERM
mkdir -p "$work/bin"
cp "$repository/bootstrap/lib.sh" "$repository/bootstrap/packages.sh" "$repository/bootstrap/herdr-codex-state.py" "$work/"
sed '$d' "$repository/bootstrap/coding-agents.sh" >"$work/bootstrap.sh"
cat >>"$work/bootstrap.sh" <<'EOF'
bootstrap_init() { PLATFORM=${TEST_PLATFORM:-macos}; }
install_agents() { :; }
install_revdiff() { :; }
install_revdiff_integrations() { :; }
provision_harness() { :; }
install_herdr_pi_integration() { : >"$PI_READY"; }
main
EOF
for utility in python3 jq awk cat chmod cmp cp date dirname find grep ln mkdir mktemp mv rm sed sh; do
  ln -s "$(command -v "$utility")" "$work/bin/$utility"
done
cat >"$work/bin/herdr" <<'EOF'
#!/bin/sh
set -eu
[ -f "$PI_READY" ]
[ "$*" = 'integration install codex' ]
printf '%s\n' "$*" >>"$HERDR_CALLS"
exec python3 "$NATIVE_FIXTURE"
EOF
chmod +x "$work/bin/herdr"
cat >"$work/native-fixture.py" <<'EOF'
import json
import os
from pathlib import Path
import shlex
import sys

home = Path(os.environ['CODEX_HOME'])
assert home.is_dir()
if os.environ.get('NATIVE_NO_FILES') == '1':
    sys.exit(0)
script = home / 'herdr-agent-state.sh'
script.write_text('#!/bin/sh\n# installed by herdr\n# HERDR_INTEGRATION_ID=codex\n')
if os.environ.get('NATIVE_FAIL') == '1':
    sys.exit(42)
hooks_file = home / 'hooks.json'
hooks = json.loads(hooks_file.read_text()) if hooks_file.exists() else {}
rules = hooks.setdefault('hooks', {}).setdefault('SessionStart', [])
command = shlex.join(['bash', str(script), 'session'])
# Fixture installation writes one managed registration, leaving other hooks.
rules[:] = [rule for rule in rules if not any(hook.get('command') == command for hook in rule['hooks'])]
rules.append({'hooks': [{'type': 'command', 'command': command, 'timeout': 10}]})
hooks_file.write_text(json.dumps(hooks))
config = home / 'config.toml'
text = config.read_text() if config.exists() else ''
assert '[features]' not in text  # Test fixtures that need installation have no features table.
config.write_text(text + '\n[features]\nhooks = true\n')
EOF
PATH="$work/bin"
HERDR_CALLS="$work/herdr-calls"
PI_READY="$work/pi-ready"
NATIVE_FIXTURE="$work/native-fixture.py"
export PATH HERDR_CALLS PI_READY NATIVE_FIXTURE

fixture() {
  HOME="$work/$1"
  export HOME
  unset CODEX_HOME NATIVE_FAIL NATIVE_NO_FILES
  codex_home="$HOME/.codex"
  : >"$HERDR_CALLS"
  rm -f "$PI_READY"
}

run_bootstrap() {
  sh "$work/bootstrap.sh" >"$work/output" 2>"$work/error"
}

fixture fresh
[ ! -e "$codex_home" ]
run_bootstrap
grep -Fxq 'integration install codex' "$HERDR_CALLS"
python3 "$work/herdr-codex-state.py" "$codex_home" | jq -e '.state == "complete"' >/dev/null
: >"$HERDR_CALLS"
run_bootstrap
[ ! -s "$HERDR_CALLS" ]
[ ! -d "$HOME/.dotfiles-backups" ]

# Script-only leftovers must be repaired, not mistaken for complete integration.
fixture partial
mkdir -p "$codex_home"
printf '#!/bin/sh\n# installed by herdr\n# HERDR_INTEGRATION_ID=codex\n' >"$codex_home/herdr-agent-state.sh"
printf '# preserve comment\nmodel = "fixture-model"\n' >"$codex_home/config.toml"
printf '{"hooks":{"SessionStart":[{"hooks":[{"type":"command","command":"echo user-hook"}]}]}}\n' >"$codex_home/hooks.json"
chmod 600 "$codex_home/config.toml"
cp "$codex_home/config.toml" "$work/config-before"
cp "$codex_home/hooks.json" "$work/hooks-before"
cp "$codex_home/herdr-agent-state.sh" "$work/script-before"
run_bootstrap
for name in config.toml hooks.json herdr-agent-state.sh; do
  backup=$(find "$HOME/.dotfiles-backups" -type f -name "$name" -print)
  case $name in
    config.toml) cmp "$backup" "$work/config-before" ;;
    hooks.json) cmp "$backup" "$work/hooks-before" ;;
    herdr-agent-state.sh) cmp "$backup" "$work/script-before" ;;
  esac
done
grep -Fq 'Codex configuration backup:' "$work/output"
grep -Fq 'preserve comment' "$codex_home/config.toml"
grep -Fq 'fixture-model' "$codex_home/config.toml"
grep -Fq 'user-hook' "$codex_home/hooks.json"

fixture disabled
mkdir -p "$codex_home"
printf '[features]\nhooks = false\n' >"$codex_home/config.toml"
cp "$codex_home/config.toml" "$work/config-before"
if run_bootstrap; then exit 1; fi
grep -Fq 'explicitly disabled' "$work/error"
cmp "$work/config-before" "$codex_home/config.toml"
[ ! -s "$HERDR_CALLS" ]
[ ! -d "$HOME/.dotfiles-backups" ]

for invalid in json toml; do
  fixture "invalid-$invalid"
  mkdir -p "$codex_home"
  case $invalid in
    json) printf '{invalid\n' >"$codex_home/hooks.json" ;;
    toml) printf '[features\n' >"$codex_home/config.toml" ;;
  esac
  if run_bootstrap; then exit 1; fi
  grep -Fq 'Herdr Codex integration conflict' "$work/error"
  [ ! -s "$HERDR_CALLS" ]
  [ ! -e "$codex_home/herdr-agent-state.sh" ]
done

fixture symlink
mkdir -p "$codex_home"
printf 'model = "fixture-model"\n' >"$HOME/versioned.toml"
ln -s "$HOME/versioned.toml" "$codex_home/config.toml"
if run_bootstrap; then exit 1; fi
grep -Fq 'must be a regular file' "$work/error"
[ -L "$codex_home/config.toml" ]
[ ! -s "$HERDR_CALLS" ]

fixture custom
CODEX_HOME="$HOME/Codex's custom home"
export CODEX_HOME
run_bootstrap
[ -f "$CODEX_HOME/herdr-agent-state.sh" ]
[ ! -e "$codex_home" ]

fixture failure
mkdir -p "$codex_home"
printf 'model = "fixture-model"\n' >"$codex_home/config.toml"
cp "$codex_home/config.toml" "$work/config-before"
status=0
NATIVE_FAIL=1 sh "$work/bootstrap.sh" >"$work/output" 2>"$work/error" || status=$?
[ "$status" = 42 ]
grep -Fq 'may have partially changed' "$work/error"
grep -Fq 'Codex configuration backup:' "$work/output"
backup=$(find "$HOME/.dotfiles-backups" -type f -name config.toml -print)
cmp "$backup" "$work/config-before"
[ -f "$codex_home/herdr-agent-state.sh" ]
[ ! -e "$codex_home/hooks.json" ]
run_bootstrap
python3 "$work/herdr-codex-state.py" "$codex_home" | jq -e '.state == "complete"' >/dev/null

fixture no-artifacts
if NATIVE_NO_FILES=1 run_bootstrap; then exit 1; fi
grep -Fq 'validation failed' "$work/error"
grep -Fq 'may have partially changed' "$work/error"

fixture unavailable-python
mv "$work/bin/python3" "$work/bin/python3-real"
printf '#!/bin/sh\nprintf "Python 3.11 or newer required\\n" >&2\nexit 2\n' >"$work/bin/python3"
chmod +x "$work/bin/python3"
if run_bootstrap; then exit 1; fi
grep -Fq 'Python 3.11+' "$work/error"
[ ! -s "$HERDR_CALLS" ]
[ ! -e "$codex_home" ]
rm "$work/bin/python3"
mv "$work/bin/python3-real" "$work/bin/python3"
printf 'Herdr Codex bootstrap, backups, repairs, conflicts, custom homes, and failure checks passed.\n'

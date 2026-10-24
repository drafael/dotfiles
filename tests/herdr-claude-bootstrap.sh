#!/bin/sh
set -eu

repository=$(CDPATH= cd -- "$(dirname -- "$0")/.." && pwd)
work=$(mktemp -d "${TMPDIR:-/tmp}/herdr-claude-bootstrap-test.XXXXXX")
trap 'rm -rf "$work"' EXIT HUP INT TERM
mkdir -p "$work/bin"
cp "$repository/bootstrap/lib.sh" "$repository/bootstrap/packages.sh" "$repository/bootstrap/herdr-claude-state.py" "$work/"
sed '$d' "$repository/bootstrap/coding-agents.sh" >"$work/bootstrap.sh"
cat >>"$work/bootstrap.sh" <<'EOF'
bootstrap_init() { PLATFORM=${TEST_PLATFORM:-macos}; }
install_agents() { :; }
install_revdiff() { :; }
install_revdiff_integrations() { :; }
provision_harness() { :; }
install_herdr_pi_integration() { : >"$PI_READY"; }
install_herdr_codex_integration() { [ -f "$PI_READY" ]; : >"$CODEX_READY"; }
main
EOF
sed '$d' "$repository/bootstrap/verify.sh" >"$work/verify.sh"
cat >>"$work/verify.sh" <<'EOF'
bootstrap_init() { PLATFORM=macos; }
refresh_standard_paths() { :; }
set_java_environment() { :; }
print_command_version() { :; }
print_yazi_support() { :; }
print_font_support() { :; }
print_harness_status() { :; }
herdr_codex_state() { printf '{"state":"complete"}\n'; }
main
EOF
for utility in python3 jq awk cat chmod cmp cp date dirname env find grep ln mkdir mktemp mv rm sed sh; do
  ln -s "$(command -v "$utility")" "$work/bin/$utility"
done
cat >"$work/bin/herdr" <<'EOF'
#!/bin/sh
set -eu
[ -f "$PI_READY" ]
[ -f "$CODEX_READY" ]
[ "$*" = 'integration install claude' ]
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

home = Path(os.environ['CLAUDE_CONFIG_DIR'])
assert home.is_dir()
if os.environ.get('NATIVE_NO_FILES') == '1':
    sys.exit(0)
script = home / 'hooks/herdr-agent-state.sh'
script.parent.mkdir(exist_ok=True)
script.write_text('#!/bin/sh\n# installed by herdr\n# HERDR_INTEGRATION_ID=claude\n')
if os.environ.get('NATIVE_FAIL') == '1':
    sys.exit(42)
if os.environ.get('NATIVE_NO_REGISTRATION') == '1':
    sys.exit(0)
settings_file = home / 'settings.json'
settings = json.loads(settings_file.read_text()) if settings_file.exists() else {}
rules = settings.setdefault('hooks', {}).setdefault('SessionStart', [])
command = shlex.join(['bash', str(script), 'session'])
rules.append({'matcher': '^(startup|resume|clear|compact|fork)$',
              'hooks': [{'type': 'command', 'command': command, 'timeout': 10}]})
settings_file.write_text(json.dumps(settings))
EOF
PATH="$work/bin"
HERDR_CALLS="$work/herdr-calls"
PI_READY="$work/pi-ready"
CODEX_READY="$work/codex-ready"
NATIVE_FIXTURE="$work/native-fixture.py"
export PATH HERDR_CALLS PI_READY CODEX_READY NATIVE_FIXTURE

fixture() {
  HOME="$work/$1"
  export HOME
  unset CLAUDE_CONFIG_DIR NATIVE_FAIL NATIVE_NO_FILES NATIVE_NO_REGISTRATION
  claude_home="$HOME/.claude"
  : >"$HERDR_CALLS"
  rm -f "$PI_READY" "$CODEX_READY"
}

run_bootstrap() {
  sh "$work/bootstrap.sh" >"$work/output" 2>"$work/error"
}

verify_state() {
  sh "$work/verify.sh" >"$work/verify-output" 2>"$work/verify-error"
  grep -Fxq "Herdr Claude integration: $1" "$work/verify-output"
}

fixture fresh
[ ! -e "$claude_home" ]
verify_state missing
[ ! -e "$claude_home" ]
run_bootstrap
grep -Fxq 'integration install claude' "$HERDR_CALLS"
python3 "$work/herdr-claude-state.py" "$claude_home" | jq -e '.state == "complete"' >/dev/null
verify_state complete
printf '# preserve local generated-script edit\n' >>"$claude_home/hooks/herdr-agent-state.sh"
cp "$claude_home/settings.json" "$work/settings-before"
cp "$claude_home/hooks/herdr-agent-state.sh" "$work/script-before"
: >"$HERDR_CALLS"
run_bootstrap
[ ! -s "$HERDR_CALLS" ]
cmp "$work/settings-before" "$claude_home/settings.json"
cmp "$work/script-before" "$claude_home/hooks/herdr-agent-state.sh"
[ ! -d "$HOME/.dotfiles-backups" ]

fixture partial
mkdir -p "$claude_home/hooks"
printf '#!/bin/sh\n# installed by herdr\n# HERDR_INTEGRATION_ID=claude\n' >"$claude_home/hooks/herdr-agent-state.sh"
printf '{"model":"fixture-model","enabledPlugins":{"fixture@local":true},"hooks":{"SessionStart":[{"hooks":[{"type":"command","command":"echo user-hook"}]}],"Stop":[{"hooks":[{"type":"command","command":"echo stop-hook"}]}]}}\n' >"$claude_home/settings.json"
chmod 600 "$claude_home/settings.json"
cp "$claude_home/settings.json" "$work/settings-before"
cp "$claude_home/hooks/herdr-agent-state.sh" "$work/script-before"
verify_state partial
run_bootstrap
backup=$(find "$HOME/.dotfiles-backups" -type f -name settings.json -print)
cmp "$backup" "$work/settings-before"
backup=$(find "$HOME/.dotfiles-backups" -type f -name herdr-agent-state.sh -print)
cmp "$backup" "$work/script-before"
grep -Fq 'Claude configuration backup:' "$work/output"
jq -e '.model == "fixture-model" and .enabledPlugins["fixture@local"] == true and .hooks.SessionStart[0].hooks[0].command == "echo user-hook" and .hooks.Stop[0].hooks[0].command == "echo stop-hook"' "$claude_home/settings.json" >/dev/null
python3 - "$claude_home/settings.json" "$HOME/.dotfiles-backups" <<'PY'
from pathlib import Path
import stat
import sys
assert stat.S_IMODE(Path(sys.argv[1]).stat().st_mode) == 0o600
backup = next(Path(sys.argv[2]).rglob('settings.json'))
assert stat.S_IMODE(backup.stat().st_mode) == 0o600
PY
verify_state complete

# A registration left behind without its script is repaired too.
fixture registration-only
mkdir -p "$claude_home"
cp "$work/settings-before" "$claude_home/settings.json"
run_bootstrap
rm "$claude_home/hooks/herdr-agent-state.sh"
: >"$HERDR_CALLS"
run_bootstrap
grep -Fxq 'integration install claude' "$HERDR_CALLS"
verify_state complete

for conflict in disabled invalid-json script-collision custom-matcher; do
  fixture "$conflict"
  mkdir -p "$claude_home/hooks"
  case $conflict in
    disabled) printf '{"disableAllHooks":true}\n' >"$claude_home/settings.json" ;;
    invalid-json) printf '{invalid "private_value":"do-not-print"\n' >"$claude_home/settings.json" ;;
    script-collision) printf '# local custom hook\n' >"$claude_home/hooks/herdr-agent-state.sh" ;;
    custom-matcher)
      run_bootstrap
      python3 - "$claude_home/settings.json" <<'PY'
import json
from pathlib import Path
import sys
path = Path(sys.argv[1])
settings = json.loads(path.read_text())
settings['hooks']['SessionStart'][0]['matcher'] = 'resume'
path.write_text(json.dumps(settings))
PY
      : >"$HERDR_CALLS"
      ;;
  esac
  if [ -f "$claude_home/settings.json" ]; then cp "$claude_home/settings.json" "$work/conflict-before"; fi
  verify_state conflict
  if run_bootstrap; then exit 1; fi
  grep -Fq 'Herdr Claude integration conflict' "$work/error"
  if grep -Fq 'do-not-print' "$work/error"; then exit 1; fi
  [ ! -s "$HERDR_CALLS" ]
  [ ! -d "$HOME/.dotfiles-backups" ]
  if [ -f "$claude_home/settings.json" ]; then cmp "$work/conflict-before" "$claude_home/settings.json"; fi
done

for link in settings hooks home script; do
  fixture "symlink-$link"
  mkdir -p "$claude_home"
  case $link in
    settings)
      printf '{}\n' >"$HOME/versioned.json"
      ln -s "$HOME/versioned.json" "$claude_home/settings.json"
      ;;
    hooks)
      mkdir "$HOME/versioned-hooks"
      ln -s "$HOME/versioned-hooks" "$claude_home/hooks"
      ;;
    home)
      mv "$claude_home" "$HOME/versioned-home"
      ln -s "$HOME/versioned-home" "$claude_home"
      ;;
    script)
      mkdir "$claude_home/hooks"
      printf '# local script\n' >"$HOME/versioned.sh"
      ln -s "$HOME/versioned.sh" "$claude_home/hooks/herdr-agent-state.sh"
      ;;
  esac
  if run_bootstrap; then exit 1; fi
  [ ! -s "$HERDR_CALLS" ]
  [ ! -d "$HOME/.dotfiles-backups" ]
done

fixture custom
CLAUDE_CONFIG_DIR="$HOME/Claude's custom home"
export CLAUDE_CONFIG_DIR
run_bootstrap
[ -f "$CLAUDE_CONFIG_DIR/hooks/herdr-agent-state.sh" ]
[ ! -e "$claude_home" ]
verify_state complete

fixture failure
mkdir -p "$claude_home"
printf '{"model":"fixture-model"}\n' >"$claude_home/settings.json"
cp "$claude_home/settings.json" "$work/settings-before"
status=0
NATIVE_FAIL=1 sh "$work/bootstrap.sh" >"$work/output" 2>"$work/error" || status=$?
[ "$status" = 42 ]
grep -Fq 'may have partially changed' "$work/error"
grep -Fq 'Claude configuration backup:' "$work/output"
backup=$(find "$HOME/.dotfiles-backups" -type f -name settings.json -print)
cmp "$backup" "$work/settings-before"
[ -f "$claude_home/hooks/herdr-agent-state.sh" ]
run_bootstrap
verify_state complete

for failure in NATIVE_NO_FILES NATIVE_NO_REGISTRATION; do
  fixture "$failure"
  if env "$failure=1" sh "$work/bootstrap.sh" >"$work/output" 2>"$work/error"; then exit 1; fi
  grep -Fq 'validation failed' "$work/error"
  grep -Fq 'may have partially changed' "$work/error"
done

fixture unavailable-python
mv "$work/bin/python3" "$work/bin/python3-real"
printf '#!/bin/sh\nprintf "Python 3.11 or newer required\\n" >&2\nexit 2\n' >"$work/bin/python3"
chmod +x "$work/bin/python3"
if run_bootstrap; then exit 1; fi
grep -Fq 'Python 3.11+' "$work/error"
[ ! -s "$HERDR_CALLS" ]
[ ! -e "$claude_home" ]
rm "$work/bin/python3"
mv "$work/bin/python3-real" "$work/bin/python3"
printf 'Herdr Claude bootstrap, verification, backups, repairs, conflicts, custom homes, and failure checks passed.\n'

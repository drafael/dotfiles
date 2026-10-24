#!/bin/sh
set -eu

repository=$(CDPATH= cd -- "$(dirname -- "$0")/.." && pwd)
work=$(mktemp -d "${TMPDIR:-/tmp}/herdr-opencode-bootstrap-test.XXXXXX")
trap 'rm -rf "$work"' EXIT HUP INT TERM
mkdir -p "$work/bin" "$work/native-temporaries"
cp "$repository/bootstrap/lib.sh" "$repository/bootstrap/packages.sh" "$repository/bootstrap/herdr-opencode-state.py" "$work/"
sed '$d' "$repository/bootstrap/coding-agents.sh" >"$work/bootstrap.sh"
cat >>"$work/bootstrap.sh" <<'EOF'
bootstrap_init() { PLATFORM=${TEST_PLATFORM:-macos}; }
install_agents() { :; }
install_revdiff() { :; }
install_revdiff_integrations() { :; }
provision_harness() { :; }
install_herdr_pi_integration() { :; }
install_herdr_codex_integration() { :; }
install_herdr_claude_integration() { : >"$CLAUDE_READY"; }
install_herdr_copilot_integration() { :; }
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
herdr_claude_state() { printf '{"state":"complete"}\n'; }
herdr_copilot_state() { printf '{"state":"complete"}\n'; }
main
EOF
for utility in python3 jq awk cat chmod cmp cp date dirname env find grep ln mkdir mktemp mv rm sed sh; do
  ln -s "$(command -v "$utility")" "$work/bin/$utility"
done
cat >"$work/bin/herdr" <<'EOF'
#!/bin/sh
set -eu
[ -f "$CLAUDE_READY" ]
[ "$*" = 'integration install opencode' ]
printf '%s\n' "$*" >>"$HERDR_CALLS"
exec python3 "$NATIVE_FIXTURE"
EOF
chmod +x "$work/bin/herdr"
cat >"$work/native-fixture.py" <<'EOF'
import json
import os
from pathlib import Path
import sys

# Match Herdr's fixed destination, deliberately ignoring OpenCode/XDG overrides.
home = Path(os.environ['HOME']) / '.config/opencode'
assert home.is_dir()
if os.environ.get('NATIVE_NO_FILES') == '1':
    sys.exit(0)
for relative, integration_id in (
    ('plugins/herdr-agent-state.js', 'opencode'),
    ('herdr-tui-session.js', 'opencode-tui'),
    ('herdr-opencode/tui.js', 'opencode-tui-v2'),
):
    path = home / relative
    path.parent.mkdir(exist_ok=True)
    path.write_text(f'// installed by herdr\n// HERDR_INTEGRATION_ID={integration_id}\n')
    if os.environ.get('NATIVE_FAIL') == '1':
        sys.exit(42)
if os.environ.get('NATIVE_NO_REGISTRATION') == '1':
    sys.exit(0)
for relative, key, reference in (
    ('tui.jsonc', 'plugin', './herdr-tui-session.js'),
    ('cli.json', 'plugins', './herdr-opencode'),
):
    path = home / relative
    text = path.read_text() if path.exists() else '{}'
    # Fixtures use one leading comment; full JSONC parsing is tested separately.
    comment, text = text.split('\n', 1) if text.startswith('//') else ('', text)
    config = json.loads(text)
    plugins = config.setdefault(key, [])
    if reference not in plugins:
        plugins.append(reference)
    path.write_text((comment + '\n' if comment else '') + json.dumps(config))
EOF
PATH="$work/bin"
TMPDIR="$work/native-temporaries"
HERDR_CALLS="$work/herdr-calls"
CLAUDE_READY="$work/claude-ready"
NATIVE_FIXTURE="$work/native-fixture.py"
export PATH TMPDIR HERDR_CALLS CLAUDE_READY NATIVE_FIXTURE

fixture() {
  HOME="$work/$1"
  export HOME
  unset OPENCODE_CONFIG_DIR XDG_CONFIG_HOME NATIVE_FAIL NATIVE_NO_FILES NATIVE_NO_REGISTRATION
  opencode_home="$HOME/.config/opencode"
  : >"$HERDR_CALLS"
  rm -f "$CLAUDE_READY"
}

run_bootstrap() {
  sh "$work/bootstrap.sh" >"$work/output" 2>"$work/error"
}

verify_state() {
  sh "$work/verify.sh" >"$work/verify-output" 2>"$work/verify-error"
  grep -Fxq "Herdr OpenCode integration: $1" "$work/verify-output"
}

assert_no_alias() {
  [ -z "$(find "$TMPDIR" -name 'herdr-opencode-home.*' -print)" ]
}

fixture fresh
verify_state missing
[ ! -e "$opencode_home" ]
run_bootstrap
grep -Fxq 'integration install opencode' "$HERDR_CALLS"
verify_state complete
fresh_home=$opencode_home
printf '// preserve local generated-plugin edit\n' >>"$opencode_home/plugins/herdr-agent-state.js"
cp -R "$opencode_home" "$work/complete-before"
: >"$HERDR_CALLS"
run_bootstrap
[ ! -s "$HERDR_CALLS" ]
for relative in plugins/herdr-agent-state.js herdr-tui-session.js herdr-opencode/tui.js tui.jsonc cli.json; do
  cmp "$opencode_home/$relative" "$work/complete-before/$relative"
done
[ ! -d "$HOME/.dotfiles-backups" ]
assert_no_alias

fixture partial
mkdir -p "$opencode_home"
cp -R "$fresh_home/." "$opencode_home/"
printf '// preserve comment\n{"theme":"fixture-theme","plugin":["user-tui"]}\n' >"$opencode_home/tui.jsonc"
printf '{"fixtureOption":true,"plugins":["user-cli"]}\n' >"$opencode_home/cli.json"
printf '{"model":"fixture-model"}\n' >"$opencode_home/opencode.json"
printf '// fixture user plugin\n' >"$opencode_home/plugins/user.ts"
chmod 600 "$opencode_home/cli.json"
cp -R "$opencode_home" "$work/partial-before"
verify_state partial
run_bootstrap
for relative in plugins/herdr-agent-state.js herdr-tui-session.js herdr-opencode/tui.js tui.jsonc cli.json; do
  backup=$(find "$HOME/.dotfiles-backups" -type f -name "${relative##*/}" -print)
  cmp "$backup" "$work/partial-before/$relative"
done
grep -Fq 'OpenCode configuration backup:' "$work/output"
grep -Fq 'preserve comment' "$opencode_home/tui.jsonc"
grep -Fq 'fixture-theme' "$opencode_home/tui.jsonc"
grep -Fq 'user-tui' "$opencode_home/tui.jsonc"
jq -e '.fixtureOption == true and .plugins[0] == "user-cli"' "$opencode_home/cli.json" >/dev/null
cmp "$opencode_home/opencode.json" "$work/partial-before/opencode.json"
cmp "$opencode_home/plugins/user.ts" "$work/partial-before/plugins/user.ts"
python3 - "$opencode_home/cli.json" "$HOME/.dotfiles-backups" <<'PY'
from pathlib import Path
import stat
import sys
assert stat.S_IMODE(Path(sys.argv[1]).stat().st_mode) == 0o600
assert stat.S_IMODE(next(Path(sys.argv[2]).rglob('cli.json')).stat().st_mode) == 0o600
PY
verify_state complete

# Losing only the V2 bridge must not look complete because the server plugin exists.
rm "$opencode_home/herdr-opencode/tui.js"
: >"$HERDR_CALLS"
run_bootstrap
grep -Fxq 'integration install opencode' "$HERDR_CALLS"
verify_state complete

for conflict in invalid-json collision legacy custom-options; do
  fixture "$conflict"
  mkdir -p "$opencode_home/plugins"
  case $conflict in
    invalid-json) printf '{invalid "private_value":"do-not-print"\n' >"$opencode_home/tui.jsonc" ;;
    collision) printf '// local plugin\n' >"$opencode_home/plugins/herdr-agent-state.js" ;;
    legacy) printf '// old plugin\n' >"$opencode_home/plugins/herdr-agent-state.ts" ;;
    custom-options) printf '{"plugins":[["./herdr-opencode",{"enabled":false}]]}\n' >"$opencode_home/cli.json" ;;
  esac
  cp -R "$opencode_home" "$work/$conflict-before"
  verify_state conflict
  if run_bootstrap; then exit 1; fi
  grep -Fq 'Herdr OpenCode integration conflict' "$work/error"
  if grep -Fq 'do-not-print' "$work/error"; then exit 1; fi
  [ ! -s "$HERDR_CALLS" ]
  [ ! -d "$HOME/.dotfiles-backups" ]
  python3 - "$opencode_home" "$work/$conflict-before" <<'PY'
from pathlib import Path
import sys
def contents(root):
    return {str(p.relative_to(root)):p.read_bytes() for p in root.rglob('*') if p.is_file()}
assert contents(Path(sys.argv[1])) == contents(Path(sys.argv[2]))
PY
done

for link in tui.jsonc cli.json plugins herdr-opencode; do
  fixture "symlink-$link"
  mkdir -p "$opencode_home"
  if [ "$link" = plugins ] || [ "$link" = herdr-opencode ]; then
    mkdir "$HOME/versioned-target"
  else
    printf '{}\n' >"$HOME/versioned-target"
  fi
  ln -s "$HOME/versioned-target" "$opencode_home/$link"
  if run_bootstrap; then exit 1; fi
  [ -L "$opencode_home/$link" ]
  [ ! -s "$HERDR_CALLS" ]
done

for destination in xdg custom; do
  fixture "$destination"
  XDG_CONFIG_HOME="$HOME/custom xdg"
  export XDG_CONFIG_HOME
  if [ "$destination" = custom ]; then
    OPENCODE_CONFIG_DIR="$HOME/OpenCode's custom config"
    export OPENCODE_CONFIG_DIR
    expected=$OPENCODE_CONFIG_DIR
  else
    expected="$XDG_CONFIG_HOME/opencode"
  fi
  run_bootstrap
  [ -f "$expected/plugins/herdr-agent-state.js" ]
  [ ! -e "$opencode_home" ]
  verify_state complete
  assert_no_alias
done

fixture failure
OPENCODE_CONFIG_DIR="$HOME/custom-failure"
export OPENCODE_CONFIG_DIR
mkdir -p "$OPENCODE_CONFIG_DIR"
printf '{"plugins":["user-cli"]}\n' >"$OPENCODE_CONFIG_DIR/cli.json"
cp "$OPENCODE_CONFIG_DIR/cli.json" "$work/cli-before"
status=0
NATIVE_FAIL=1 sh "$work/bootstrap.sh" >"$work/output" 2>"$work/error" || status=$?
[ "$status" = 42 ]
grep -Fq 'may have partially changed' "$work/error"
grep -Fq 'OpenCode configuration backup:' "$work/output"
backup=$(find "$HOME/.dotfiles-backups" -type f -name cli.json -print)
cmp "$backup" "$work/cli-before"
[ -f "$OPENCODE_CONFIG_DIR/plugins/herdr-agent-state.js" ]
assert_no_alias
run_bootstrap
verify_state complete

for failure in NATIVE_NO_FILES NATIVE_NO_REGISTRATION; do
  fixture "$failure"
  if env "$failure=1" sh "$work/bootstrap.sh" >"$work/output" 2>"$work/error"; then exit 1; fi
  grep -Fq 'validation failed' "$work/error"
  grep -Fq 'may have partially changed' "$work/error"
  assert_no_alias
done

fixture unavailable-python
mv "$work/bin/python3" "$work/bin/python3-real"
printf '#!/bin/sh\nprintf "Python 3.11 or newer required\\n" >&2\nexit 2\n' >"$work/bin/python3"
chmod +x "$work/bin/python3"
if run_bootstrap; then exit 1; fi
grep -Fq 'Python 3.11+' "$work/error"
[ ! -s "$HERDR_CALLS" ]
[ ! -e "$opencode_home" ]
rm "$work/bin/python3"
mv "$work/bin/python3-real" "$work/bin/python3"
printf 'Herdr OpenCode bootstrap, verification, backups, repairs, conflicts, custom roots, and alias cleanup checks passed.\n'

#!/bin/sh
set -eu

repository=$(CDPATH= cd -- "$(dirname -- "$0")/.." && pwd)
work=$(mktemp -d "${TMPDIR:-/tmp}/herdr-config-links-test.XXXXXX")
work=$(CDPATH= cd -- "$work" && pwd)
trap 'rm -rf "$work"' EXIT HUP INT TERM
mkdir -p "$work/repository/bootstrap" "$work/repository/.config/herdr" "$work/repository/.config/ordinary" "$work/bin"
cp "$repository/bootstrap/lib.sh" "$repository/bootstrap/packages.sh" "$work/repository/bootstrap/"
cp "$repository/.config/herdr/config.toml" "$repository/.config/herdr/.gitignore" "$work/repository/.config/herdr/"
printf 'ordinary configuration\n' >"$work/repository/.config/ordinary/config"
app_source="$work/repository/.config/herdr-app"
mkdir -p "$app_source/layouts" "$app_source/themes" "$app_source/mods/catppuccin-tabs"
cp "$repository/.config/herdr-app/settings.json" "$repository/.config/herdr-app/.gitignore" "$app_source/"
cp "$repository/.config/herdr-app/layouts/catppuccin.json" "$app_source/layouts/"
cp "$repository/.config/herdr-app/themes/catppuccin-frappe.json" "$app_source/themes/"
printf '// personal mod fixture\n' >"$app_source/mods/catppuccin-tabs/main.js"
sed '$d' "$repository/bootstrap/link-dotfiles.sh" >"$work/repository/bootstrap/link-dotfiles.sh"
cat >>"$work/repository/bootstrap/link-dotfiles.sh" <<'EOF'
bootstrap_init() { PLATFORM=${TEST_PLATFORM:-macos}; }
# Other platform links and login-shell changes are outside this test boundary.
link_terminal_config() { :; }
link_root_dotfiles() { :; }
main
EOF
cat >"$work/bin/herdr" <<'EOF'
#!/bin/sh
printf '%s\n' "$*" >>"$HERDR_CALLS"
exit 99
EOF
chmod +x "$work/bin/herdr"
PATH="$work/bin:$PATH"
HERDR_CALLS="$work/herdr-calls"
export PATH HERDR_CALLS
: >"$HERDR_CALLS"
source_file="$work/repository/.config/herdr/config.toml"

fixture() {
  HOME="$work/$1"
  export HOME
  unset XDG_CONFIG_HOME HERDR_CONFIG_PATH HERDR_APP_HOME
  herdr_home="$HOME/.config/herdr"
  mkdir -p "$HOME/.config"
}

run_bootstrap() {
  sh "$work/repository/bootstrap/link-dotfiles.sh" >"$work/output" 2>"$work/error"
}

assert_link() {
  [ -d "$herdr_home" ]
  [ ! -L "$herdr_home" ]
  [ -L "$herdr_home/config.toml" ]
  [ "$(readlink "$herdr_home/config.toml")" = "$source_file" ]
  [ ! -e "$herdr_home/.gitignore" ]
  app_home=${HERDR_APP_HOME:-${XDG_CONFIG_HOME:-$HOME/.config}/herdr-app}
  for directory in '' layouts themes mods; do
    [ -d "$app_home${directory:+/$directory}" ]
    [ ! -L "$app_home${directory:+/$directory}" ]
  done
  for relative in settings.json layouts/catppuccin.json themes/catppuccin-frappe.json mods/catppuccin-tabs; do
    [ -L "$app_home/$relative" ]
    [ "$(readlink "$app_home/$relative")" = "$app_source/$relative" ]
  done
}

for platform in macos ubuntu fedora arch omarchy; do
  fixture "fresh-$platform"
  TEST_PLATFORM=$platform
  export TEST_PLATFORM
  run_bootstrap
  assert_link
  [ -L "$HOME/.config/ordinary" ]
  [ ! -d "$HOME/.dotfiles-backups" ]
  run_bootstrap
  assert_link
  [ ! -d "$HOME/.dotfiles-backups" ]
done

fixture existing-runtime
mkdir -p "$herdr_home/session-snapshots"
printf 'machine-local session\n' >"$herdr_home/session.json"
printf 'machine-local log\n' >"$herdr_home/herdr-server.log"
printf 'snapshot\n' >"$herdr_home/session-snapshots/001.json"
printf 'lock\n' >"$herdr_home/.plugins.lock"
printf 'onboarding = true\n' >"$herdr_home/config.toml"
chmod 600 "$herdr_home/config.toml"
cp "$herdr_home/config.toml" "$work/config-before"
# Bind relative to cwd to avoid Unix socket path limits in long macOS TMPDIRs.
python3 - "$herdr_home" <<'PY'
import os
import socket
import sys
os.chdir(sys.argv[1])
with socket.socket(socket.AF_UNIX) as server:
    server.bind('herdr.sock')
PY
run_bootstrap
assert_link
backup=$(find "$HOME/.dotfiles-backups" -name config.toml -print)
cmp "$backup" "$work/config-before"
[ "$(find "$HOME/.dotfiles-backups" -type f | wc -l | tr -d ' ')" = 1 ]
[ -S "$herdr_home/herdr.sock" ]
grep -Fxq 'machine-local session' "$herdr_home/session.json"
grep -Fxq 'machine-local log' "$herdr_home/herdr-server.log"
grep -Fxq snapshot "$herdr_home/session-snapshots/001.json"
grep -Fxq lock "$herdr_home/.plugins.lock"
python3 - "$backup" <<'PY'
from pathlib import Path
import stat
import sys
assert stat.S_IMODE(Path(sys.argv[1]).stat().st_mode) == 0o600
PY
run_bootstrap
[ "$(find "$HOME/.dotfiles-backups" -name config.toml | wc -l | tr -d ' ')" = 1 ]

fixture custom-xdg
XDG_CONFIG_HOME="$HOME/custom config"
export XDG_CONFIG_HOME
herdr_home="$XDG_CONFIG_HOME/herdr"
run_bootstrap
assert_link
[ ! -e "$HOME/.config/herdr" ]
[ -L "$XDG_CONFIG_HOME/ordinary" ]

# Application writes go through the file link; a rerun must not reset them.
printf '\n# preference saved through the application path\n' >>"$herdr_home/config.toml"
grep -Fq 'preference saved through the application path' "$source_file"
run_bootstrap
grep -Fq 'preference saved through the application path' "$herdr_home/config.toml"
[ ! -d "$HOME/.dotfiles-backups" ]

fixture explicit-override
HERDR_CONFIG_PATH="$HOME/local-herdr.toml"
export HERDR_CONFIG_PATH
printf 'machine-local config override\n' >"$HERDR_CONFIG_PATH"
run_bootstrap
assert_link
grep -Fxq 'machine-local config override' "$HERDR_CONFIG_PATH"

fixture foreign-file-link
mkdir -p "$herdr_home"
printf 'local target\n' >"$HOME/local.toml"
ln -s "$HOME/local.toml" "$herdr_home/config.toml"
run_bootstrap
assert_link
backup=$(find "$HOME/.dotfiles-backups" -name config.toml -print)
[ -L "$backup" ]
[ "$(readlink "$backup")" = "$HOME/local.toml" ]
grep -Fxq 'local target' "$HOME/local.toml"

for conflict in symlink dangling-link file; do
  fixture "directory-$conflict"
  case $conflict in
    symlink)
      mkdir "$HOME/runtime-target"
      printf 'existing session\n' >"$HOME/runtime-target/session.json"
      ln -s "$HOME/runtime-target" "$herdr_home"
      ;;
    dangling-link) ln -s "$HOME/missing-runtime" "$herdr_home" ;;
    file) printf 'not a directory\n' >"$herdr_home" ;;
  esac
  if run_bootstrap; then
    printf 'invalid Herdr directory unexpectedly replaced: %s\n' "$conflict" >&2
    exit 1
  fi
  grep -Fq 'Herdr configuration directory must be a real directory' "$work/error"
  [ ! -d "$HOME/.dotfiles-backups" ]
  case $conflict in
    symlink)
      [ -L "$herdr_home" ]
      grep -Fxq 'existing session' "$HOME/runtime-target/session.json"
      ;;
    dangling-link) [ -L "$herdr_home" ] ;;
    file) grep -Fxq 'not a directory' "$herdr_home" ;;
  esac
done

# Files present only on the source workstation must never be bootstrapped,
# including ignored files inside the asset directories.
printf '{"machines":["source-only.example"]}\n' >"$app_source/shared.json"
printf '{"host":"source-only.example"}\n' >"$app_source/layouts/workstation.json"
printf '{"host":"source-only.example"}\n' >"$app_source/themes/catppuccin-local.json"
mkdir -p "$app_source/mods/catppuccin-local"
printf '// source workstation only\n' >"$app_source/mods/catppuccin-local/main.js"
fixture gui-portable-only
run_bootstrap
assert_link
for relative in shared.json layouts/workstation.json themes/catppuccin-local.json mods/catppuccin-local; do
  [ ! -e "$app_home/$relative" ]
  [ ! -L "$app_home/$relative" ]
done

fixture gui-runtime
app_home="$HOME/.config/herdr-app"
mkdir -p "$app_home/layouts/.state" "$app_home/mods/shipped" "$app_home/mods/catppuccin-tabs"
printf 'local view\n' >"$app_home/view.json"
printf '{"machines":["destination-only.example"]}\n' >"$app_home/shared.json"
printf 'local machines\n' >"$app_home/machines.json"
printf 'local click state\n' >"$app_home/layouts/.state/catppuccin.json"
printf 'shipped mod\n' >"$app_home/mods/shipped/main.js"
printf 'old personal mod\n' >"$app_home/mods/catppuccin-tabs/main.js"
printf '{"theme":"graphite"}\n' >"$app_home/settings.json"
run_bootstrap
assert_link
grep -Fxq 'local view' "$app_home/view.json"
grep -Fq 'destination-only.example' "$app_home/shared.json"
grep -Fxq 'local machines' "$app_home/machines.json"
[ ! -L "$app_home/shared.json" ]
[ ! -L "$app_home/machines.json" ]
grep -Fxq 'local click state' "$app_home/layouts/.state/catppuccin.json"
grep -Fxq 'shipped mod' "$app_home/mods/shipped/main.js"
backup=$(find "$HOME/.dotfiles-backups" -name settings.json -print)
grep -Fq graphite "$backup"
backup=$(find "$HOME/.dotfiles-backups" -path '*/catppuccin-tabs/main.js' -print)
grep -Fxq 'old personal mod' "$backup"
run_bootstrap
[ "$(find "$HOME/.dotfiles-backups" -name settings.json | wc -l | tr -d ' ')" = 1 ]

fixture gui-override
HERDR_APP_HOME="$HOME/custom GUI home"
export HERDR_APP_HOME
run_bootstrap
assert_link
[ ! -e "$HOME/.config/herdr-app" ]

for directory in '' layouts themes mods; do
  fixture "gui-conflict-${directory:-root}"
  app_home="$HOME/.config/herdr-app"
  mkdir -p "$app_home" "$HOME/foreign"
  if [ -z "$directory" ]; then rmdir "$app_home"; fi
  ln -s "$HOME/foreign" "$app_home${directory:+/$directory}"
  if run_bootstrap; then
    printf 'GUI runtime directory symlink unexpectedly replaced\n' >&2
    exit 1
  fi
  grep -Fq 'Herdr GUI configuration directory must be a real directory' "$work/error"
  [ -L "$app_home${directory:+/$directory}" ]
done

# Ignore runtime data even if it is accidentally created in the source directory.
git -C "$work/repository" init -q
for path in session.json session-snapshots/001.json herdr.sock herdr-server.log config.toml.bak; do
  git -C "$work/repository" check-ignore --no-index -q ".config/herdr/$path"
done
for path in config.toml .gitignore; do
  if git -C "$work/repository" check-ignore --no-index -q ".config/herdr/$path"; then
    printf 'portable Herdr source unexpectedly ignored: %s\n' "$path" >&2
    exit 1
  fi
done
for path in view.json shared.json machines.json windows.json installed.json herdr-app.sock AGENTS.md layouts/.state/catppuccin.json layouts/workstation.json themes/catppuccin-local.json mods/catppuccin-local/main.js mods/catppuccin-tabs/gpui-kit.d.ts mods/catppuccin-tabs/jsconfig.json; do
  git -C "$work/repository" check-ignore --no-index -q ".config/herdr-app/$path"
done
for path in settings.json layouts/catppuccin.json themes/catppuccin-frappe.json mods/catppuccin-tabs/main.js; do
  if git -C "$work/repository" check-ignore --no-index -q ".config/herdr-app/$path"; then
    printf 'portable GUI source unexpectedly ignored: %s\n' "$path" >&2
    exit 1
  fi
done
python3 - "$repository" <<'PY'
import json, sys
from pathlib import Path
root = Path(sys.argv[1]) / '.config/herdr-app'
settings = json.loads((root / 'settings.json').read_text())
# Only visual/input/privacy preferences: no paths, host lists, core binary,
# worktree directories, or fonts dependent on the source workstation.
assert set(settings) == {
    'zoom', 'sounds', 'font_ligatures', 'terminal_line_height',
    'terminal_cell_width', 'terminal_scroll_speed', 'minimum_contrast',
    'appearance', 'telemetry', 'theme',
}
assert settings['sounds'] == {'enabled': True}
assert settings['theme'] == 'catppuccin-frappe'
assert json.loads((root / 'layouts/catppuccin.json').read_text())['theme']['dark'] == 'catppuccin-frappe'
PY
[ ! -s "$HERDR_CALLS" ]
printf 'Herdr TUI and GUI config file links, backups, runtime preservation, reruns, XDG paths, overrides, conflicts, and ignore rules passed.\n'

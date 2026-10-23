#!/bin/sh
set -eu

test_repository=$(CDPATH= cd -- "$(dirname -- "$0")/.." && pwd)
work=$(mktemp -d "${TMPDIR:-/tmp}/pi-bootstrap-test.XXXXXX")
trap 'rm -rf "$work"' EXIT HUP INT TERM
cp "$test_repository/bootstrap/lib.sh" "$test_repository/bootstrap/packages.sh" "$work/"
sed '$d' "$test_repository/bootstrap/coding-agents.sh" >"$work/coding-agents.sh"
printf '\nPLATFORM=${TEST_PLATFORM:-macos}\ninstall_agents\n' >>"$work/coding-agents.sh"
sed '$d' "$test_repository/bootstrap/coding-agents.sh" >"$work/pi-packages.sh"
printf '\ninstall_pi_packages\n' >>"$work/pi-packages.sh"
sed '$d' "$test_repository/bootstrap/coding-agents.sh" >"$work/harness-links.sh"
printf '\nPLATFORM=${TEST_PLATFORM:-macos}\nlink_harness_configuration\n' >>"$work/harness-links.sh"
mkdir -p "$work/bin" "$work/home"

# Other agents and npm are already present; none should be executed.
for tool in claude opencode codex npm; do
  printf '#!/bin/sh\nexit 99\n' >"$work/bin/$tool"
  chmod +x "$work/bin/$tool"
done

# Exercise the real download helper without downloading or installing software.
# The fixture models the managed installer's user-local Pi entrypoint.
cat >"$work/bin/curl" <<'EOF'
#!/bin/sh
set -eu
printf '%s\n' "$*" >>"$CALLS"
[ "${CURL_FAIL:-0}" = 0 ] || exit 22
[ "$1" = -fsSL ]
[ "$2" = https://pi.dev/install.sh ]
[ "$3" = -o ]
cat >"$4" <<'INSTALLER'
#!/bin/sh
set -eu
[ "${INSTALLER_FAIL:-0}" = 0 ] || exit 42
mkdir -p "$HOME/.local/bin"
printf '#!/bin/sh\nprintf "fixture-pi\\n"\n' >"$HOME/.local/bin/pi"
chmod +x "$HOME/.local/bin/pi"
INSTALLER
EOF
chmod +x "$work/bin/curl"

(
  HOME="$work/home"
  PATH="$work/bin:/usr/bin:/bin"
  CALLS="$work/downloads"
  export HOME PATH CALLS

  sh "$work/coding-agents.sh"
  grep -Fq 'https://pi.dev/install.sh' "$CALLS"
  [ "$("$HOME/.local/bin/pi")" = fixture-pi ]

  # An existing Pi must not be upgraded, migrated, or reinstalled.
  sh "$work/coding-agents.sh"
  [ "$(wc -l <"$CALLS" | tr -d ' ')" = 1 ]

  # Omarchy keeps its launchers even when Pi has not been installed yet.
  rm "$HOME/.local/bin/pi"
  TEST_PLATFORM=omarchy sh "$work/coding-agents.sh"
  [ ! -e "$HOME/.local/bin/pi" ]
  [ "$(wc -l <"$CALLS" | tr -d ' ')" = 1 ]

  if CURL_FAIL=1 sh "$work/coding-agents.sh" >"$work/download.out" 2>&1; then
    printf 'failed Pi download unexpectedly passed\n' >&2
    exit 1
  fi
  grep -Fq 'failed to download the Pi installer' "$work/download.out"
  [ ! -e "$HOME/.local/bin/pi" ]

  if INSTALLER_FAIL=1 sh "$work/coding-agents.sh" >"$work/installer.out" 2>&1; then
    printf 'failed Pi installer unexpectedly passed\n' >&2
    exit 1
  fi
  grep -Fq 'Pi installer failed with status 42' "$work/installer.out"
  [ ! -e "$HOME/.local/bin/pi" ]
)
# Keep existing Pi packages untouched and install only the missing STT package.
cat >"$work/bin/pi" <<'EOF'
#!/bin/sh
set -eu
case $1 in
  list) cat "$PI_PACKAGES" ;;
  install)
    [ "$2" = npm:pi-voice-stt ] || exit 99
    printf '%s\n' "$*" >>"$PI_PACKAGE_CALLS"
    if [ "${PI_PACKAGE_FAIL:-0}" = 1 ]; then
      printf 'fixture Pi package install failure\n' >&2
      exit 42
    fi
    printf '%s\n' "$2" >>"$PI_PACKAGES"
    ;;
  *) exit 99 ;;
esac
EOF
chmod +x "$work/bin/pi"
printf '%s\n' https://github.com/umputun/revdiff npm:pi-subagents npm:pi-web-access npm:pi-intercom >"$work/base-packages"

(
  HOME="$work/home"
  PATH="$work/bin:/usr/bin:/bin"
  PI_PACKAGES="$work/pi-packages"
  PI_PACKAGE_CALLS="$work/package-calls"
  export HOME PATH PI_PACKAGES PI_PACKAGE_CALLS
  cp "$work/base-packages" "$PI_PACKAGES"
  : >"$PI_PACKAGE_CALLS"

  sh "$work/pi-packages.sh"
  grep -Fxq 'install npm:pi-voice-stt' "$PI_PACKAGE_CALLS"
  grep -Fxq npm:pi-voice-stt "$PI_PACKAGES"

  sh "$work/pi-packages.sh"
  [ "$(wc -l <"$PI_PACKAGE_CALLS" | tr -d ' ')" = 1 ]

  cp "$work/base-packages" "$PI_PACKAGES"
  if PI_PACKAGE_FAIL=1 sh "$work/pi-packages.sh" >"$work/package.out" 2>&1; then
    printf 'failed Pi package install unexpectedly passed\n' >&2
    exit 1
  fi
  grep -Fq 'fixture Pi package install failure' "$work/package.out"
  if grep -Fxq npm:pi-voice-stt "$PI_PACKAGES"; then
    printf 'failed Pi package install was marked installed\n' >&2
    exit 1
  fi
)
# Exercise the actual link and backup helpers on every supported platform.
for test_platform in macos ubuntu fedora arch omarchy; do
  (
    HOME="$work/links-$test_platform"
    export HOME
    harness="$HOME/code/harness"
    mkdir -p "$harness/skills" "$harness/.pi/agent/themes" "$harness/.pi/agent/prompts" "$harness/.pi/agent/extensions" "$HOME/.pi/agent"
    : >"$harness/AGENTS.md"
    : >"$harness/CLAUDE.md"
    printf '{"capture":{"type":"ffmpeg"}}\n' >"$harness/.pi/agent/stt.json"
    printf '{"profile":"local"}\n' >"$HOME/.pi/agent/stt.json"
    cp "$HOME/.pi/agent/stt.json" "$work/stt-original.json"

    TEST_PLATFORM="$test_platform" sh "$work/harness-links.sh" >"$work/links.out"
    [ -L "$HOME/.pi/agent/stt.json" ]
    [ "$(readlink "$HOME/.pi/agent/stt.json")" = "$harness/.pi/agent/stt.json" ]
    cmp "$HOME/.pi/agent/stt.json" "$harness/.pi/agent/stt.json"
    backup=$(find "$HOME/.dotfiles-backups" -type f -name stt.json -print)
    cmp "$backup" "$work/stt-original.json"

    # Equivalent relative links must survive reruns without another backup.
    rm "$HOME/.pi/agent/stt.json"
    ln -s ../../code/harness/.pi/agent/stt.json "$HOME/.pi/agent/stt.json"
    TEST_PLATFORM="$test_platform" sh "$work/harness-links.sh" >"$work/links.out"
    [ "$(readlink "$HOME/.pi/agent/stt.json")" = ../../code/harness/.pi/agent/stt.json ]
    [ "$(find "$HOME/.dotfiles-backups" -type f -name stt.json | wc -l | tr -d ' ')" = 1 ]

    # Older harness checkouts must not replace a working local STT config.
    rm "$harness/.pi/agent/stt.json" "$HOME/.pi/agent/stt.json"
    cp "$work/stt-original.json" "$HOME/.pi/agent/stt.json"
    TEST_PLATFORM="$test_platform" sh "$work/harness-links.sh" >"$work/links.out" 2>"$work/links.err"
    [ ! -L "$HOME/.pi/agent/stt.json" ]
    cmp "$HOME/.pi/agent/stt.json" "$work/stt-original.json"
    grep -Fq 'stt.json not found' "$work/links.err"
  )
done
printf 'Pi installer, packages, harness links, backups, Omarchy, and failure checks passed.\n'

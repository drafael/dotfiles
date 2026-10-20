#!/bin/sh
set -eu

test_repository=$(CDPATH= cd -- "$(dirname -- "$0")/.." && pwd)
work=$(mktemp -d "${TMPDIR:-/tmp}/pi-bootstrap-test.XXXXXX")
trap 'rm -rf "$work"' EXIT HUP INT TERM
cp "$test_repository/bootstrap/lib.sh" "$test_repository/bootstrap/packages.sh" "$work/"
sed '$d' "$test_repository/bootstrap/coding-agents.sh" >"$work/coding-agents.sh"
printf '\nPLATFORM=${TEST_PLATFORM:-macos}\ninstall_agents\n' >>"$work/coding-agents.sh"
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
printf 'Pi installer, existing-install, Omarchy, and failure checks passed.\n'

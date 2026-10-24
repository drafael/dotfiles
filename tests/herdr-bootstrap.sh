#!/bin/sh
set -eu

repository=$(CDPATH= cd -- "$(dirname -- "$0")/.." && pwd)
work=$(mktemp -d "${TMPDIR:-/tmp}/herdr-bootstrap-test.XXXXXX")
trap 'rm -rf "$work"' EXIT HUP INT TERM
mkdir -p "$work/bin" "$work/home"
cp "$repository/bootstrap/lib.sh" "$repository/bootstrap/packages.sh" "$work/"
sed '$d' "$repository/bootstrap/coding-agents.sh" >"$work/coding-agents.sh"
# Keep the real Homebrew install helper, but never discover the host's brew.
cat >>"$work/coding-agents.sh" <<'EOF'
ensure_homebrew() { require_command brew; }
PLATFORM=${TEST_PLATFORM:-macos}
install_agents
EOF
sed '$d' "$repository/bootstrap/verify.sh" >"$work/verify.sh"
printf '\nprint_command_version herdr\n' >>"$work/verify.sh"

# Do not expose unrelated host tools to installation detection.
for utility in awk cat chmod cp dirname grep ln mkdir mktemp rm sh sort tr; do
  ln -s "$(command -v "$utility")" "$work/bin/$utility"
done
for tool in claude codex opencode pi npm; do
  printf '#!/bin/sh\nexit 99\n' >"$work/bin/$tool"
  chmod +x "$work/bin/$tool"
done
cat >"$work/herdr-executable" <<'EOF'
#!/bin/sh
set -eu
printf '%s\n' "$*" >>"$HERDR_CALLS"
if [ "$#" != 1 ] || [ "$1" != --version ]; then
  exit 99
fi
printf 'herdr 0.9.5\n'
EOF
cat >"$work/bin/curl" <<'EOF'
#!/bin/sh
set -eu
printf '%s\n' "$*" >>"$DOWNLOADS"
[ "${CURL_FAIL:-0}" = 0 ] || exit 22
[ "$#" = 4 ]
[ "$1" = -fsSL ]
[ "$2" = https://herdr.dev/install.sh ]
[ "$3" = -o ]
cat >"$4" <<'INSTALLER'
#!/bin/sh
set -eu
[ "${INSTALLER_FAIL:-0}" = 0 ] || exit 42
mkdir -p "$HOME/.local/bin"
cp "$HERDR_FIXTURE" "$HOME/.local/bin/herdr"
chmod +x "$HOME/.local/bin/herdr"
INSTALLER
EOF
chmod +x "$work/bin/curl"
cat >"$work/bin/brew" <<'EOF'
#!/bin/sh
set -eu
printf '%s\n' "$*" >>"$BREW_CALLS"
case "$*" in
  'list --formula herdr') [ -x "$HERDR_BIN" ] ;;
  'install herdr')
    if [ "${BREW_FAIL:-0}" = 1 ]; then
      printf 'fixture Homebrew install failure\n' >&2
      exit 42
    fi
    cp "$HERDR_FIXTURE" "$HERDR_BIN"
    chmod +x "$HERDR_BIN"
    ;;
  *) exit 99 ;;
esac
EOF
chmod +x "$work/bin/brew"

HOME="$work/home"
PATH="$work/bin"
BREW_CALLS="$work/brew-calls"
HERDR_CALLS="$work/herdr-calls"
HERDR_BIN="$work/bin/herdr"
HERDR_FIXTURE="$work/herdr-executable"
DOWNLOADS="$work/downloads"
export HOME PATH BREW_CALLS HERDR_CALLS HERDR_BIN HERDR_FIXTURE DOWNLOADS
: >"$DOWNLOADS"
: >"$BREW_CALLS"
: >"$HERDR_CALLS"

sh "$work/coding-agents.sh"
grep -Fxq 'install herdr' "$BREW_CALLS"
[ -x "$HERDR_BIN" ]
[ ! -s "$HERDR_CALLS" ]

# A second run must not install or upgrade an existing Homebrew executable.
: >"$BREW_CALLS"
sh "$work/coding-agents.sh"
[ ! -s "$BREW_CALLS" ]
[ ! -s "$HERDR_CALLS" ]

sh "$work/verify.sh" >"$work/version"
grep -Fxq 'herdr 0.9.5' "$work/version"
grep -Fxq -- --version "$HERDR_CALLS"

# Preserve executables installed outside Homebrew without executing them.
printf '#!/bin/sh\n# existing standalone Herdr\nexit 99\n' >"$HERDR_BIN"
: >"$HERDR_CALLS"
sh "$work/coding-agents.sh"
[ ! -s "$BREW_CALLS" ]
[ ! -s "$HERDR_CALLS" ]
grep -Fq 'existing standalone Herdr' "$HERDR_BIN"

rm "$HERDR_BIN"
status=0
BREW_FAIL=1 sh "$work/coding-agents.sh" >"$work/failure" 2>&1 || status=$?
[ "$status" = 42 ]
grep -Fq 'fixture Homebrew install failure' "$work/failure"
[ ! -e "$HERDR_BIN" ]

: >"$BREW_CALLS"
for platform in ubuntu fedora arch omarchy; do
  HOME="$work/home-$platform"
  export HOME
  : >"$DOWNLOADS"
  TEST_PLATFORM="$platform" sh "$work/coding-agents.sh"
  [ -x "$HOME/.local/bin/herdr" ]
  grep -Fq 'https://herdr.dev/install.sh' "$DOWNLOADS"
  [ ! -s "$HERDR_CALLS" ]

  # Repeat runs and standalone installations must not download or launch Herdr.
  : >"$DOWNLOADS"
  TEST_PLATFORM="$platform" sh "$work/coding-agents.sh"
  [ ! -s "$DOWNLOADS" ]
  printf '#!/bin/sh\n# existing standalone Herdr\nexit 99\n' >"$HOME/.local/bin/herdr"
  TEST_PLATFORM="$platform" sh "$work/coding-agents.sh"
  [ ! -s "$DOWNLOADS" ]
  grep -Fq 'existing standalone Herdr' "$HOME/.local/bin/herdr"
  rm "$HOME/.local/bin/herdr"
done
[ ! -s "$BREW_CALLS" ]
[ ! -s "$HERDR_CALLS" ]

if TEST_PLATFORM=ubuntu CURL_FAIL=1 sh "$work/coding-agents.sh" >"$work/download-failure" 2>&1; then
  printf 'failed Herdr download unexpectedly passed\n' >&2
  exit 1
fi
grep -Fq 'failed to download the Herdr installer' "$work/download-failure"
[ ! -e "$HOME/.local/bin/herdr" ]

if TEST_PLATFORM=ubuntu INSTALLER_FAIL=1 sh "$work/coding-agents.sh" >"$work/installer-failure" 2>&1; then
  printf 'failed Herdr installer unexpectedly passed\n' >&2
  exit 1
fi
grep -Fq 'Herdr installer failed with status 42' "$work/installer-failure"
[ ! -e "$HOME/.local/bin/herdr" ]

BOOTSTRAP_DIR="$work"
. "$work/lib.sh"
bootstrap_packages macos brew-formula agents | grep -Fxq herdr
printf 'Herdr installation, existing-install, version, failure, Linux, and catalog checks passed.\n'

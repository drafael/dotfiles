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
printf '\nprint_command_version herdr\nprint_command_version herdr-app\n' >>"$work/verify.sh"

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
printf '%s 0.9.5\n' "${0##*/}"
EOF
cat >"$work/bin/curl" <<'EOF'
#!/bin/sh
set -eu
printf '%s\n' "$*" >>"$DOWNLOADS"
[ "${CURL_FAIL:-0}" = 0 ] || exit 22
[ "$#" = 4 ]
[ "$1" = -fsSL ]
case "$2" in
  https://herdr.dev/install.sh) binary=herdr ;;
  https://releases.herdr.dev/app/install.sh)
    [ "${APP_CURL_FAIL:-0}" = 0 ] || exit 22
    binary=herdr-app ;;
  *) exit 99 ;;
esac
[ "$3" = -o ]
printf 'binary=%s\n' "$binary" >"$4"
cat >>"$4" <<'INSTALLER'
#!/bin/sh
set -eu
[ "${INSTALLER_FAIL:-0}" = 0 ] || exit 42
if [ "$binary" = herdr-app ]; then
  [ "${APP_INSTALLER_FAIL:-0}" = 0 ] || exit 42
  [ "${APP_NO_BINARY:-0}" = 0 ] || exit 0
fi
mkdir -p "$HOME/.local/bin"
cp "$HERDR_FIXTURE" "$HOME/.local/bin/$binary"
chmod +x "$HOME/.local/bin/$binary"
INSTALLER
EOF
chmod +x "$work/bin/curl"
cat >"$work/bin/brew" <<'EOF'
#!/bin/sh
set -eu
printf '%s\n' "$*" >>"$BREW_CALLS"
case "$*" in
  'list --formula herdr') [ -x "$HERDR_BIN" ] ;;
  'list --cask herdr-app') [ -x "$HERDR_APP_BIN" ] ;;
  'install --cask herdr-app')
    [ "${APP_BREW_FAIL:-0}" = 0 ] || exit 42
    cp "$HERDR_FIXTURE" "$HERDR_APP_BIN"
    chmod +x "$HERDR_APP_BIN"
    ;;
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
HERDR_APP_BIN="$work/bin/herdr-app"
HERDR_FIXTURE="$work/herdr-executable"
DOWNLOADS="$work/downloads"
export HOME PATH BREW_CALLS HERDR_CALLS HERDR_BIN HERDR_APP_BIN HERDR_FIXTURE DOWNLOADS
: >"$DOWNLOADS"
: >"$BREW_CALLS"
: >"$HERDR_CALLS"

sh "$work/coding-agents.sh"
grep -Fxq 'install herdr' "$BREW_CALLS"
grep -Fxq 'install --cask herdr-app' "$BREW_CALLS"
[ -x "$HERDR_BIN" ]
[ -x "$HERDR_APP_BIN" ]
[ ! -s "$HERDR_CALLS" ]

# A second run must not install or upgrade an existing Homebrew executable.
: >"$BREW_CALLS"
sh "$work/coding-agents.sh"
[ ! -s "$BREW_CALLS" ]
[ ! -s "$HERDR_CALLS" ]

sh "$work/verify.sh" >"$work/version"
grep -Fxq 'herdr 0.9.5' "$work/version"
grep -Fxq 'herdr-app 0.9.5' "$work/version"
grep -Fxq -- --version "$HERDR_CALLS"

# Preserve executables installed outside Homebrew without executing them.
printf '#!/bin/sh\n# existing standalone Herdr\nexit 99\n' >"$HERDR_BIN"
printf '#!/bin/sh\n# existing standalone GUI\nexit 99\n' >"$HERDR_APP_BIN"
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

# A missing GUI remains required even when the TUI is already present.
cp "$HERDR_FIXTURE" "$HERDR_BIN"
chmod +x "$HERDR_BIN"
rm "$HERDR_APP_BIN"
status=0
APP_BREW_FAIL=1 sh "$work/coding-agents.sh" >"$work/app-brew-failure" 2>&1 || status=$?
[ "$status" = 42 ]
[ ! -e "$HERDR_APP_BIN" ]
sh "$work/coding-agents.sh"
[ -x "$HERDR_APP_BIN" ]
rm "$HERDR_BIN" "$HERDR_APP_BIN"

: >"$BREW_CALLS"
for platform in ubuntu fedora arch omarchy; do
  HOME="$work/home-$platform"
  export HOME
  : >"$DOWNLOADS"
  TEST_PLATFORM="$platform" sh "$work/coding-agents.sh"
  [ -x "$HOME/.local/bin/herdr" ]
  [ -x "$HOME/.local/bin/herdr-app" ]
  grep -Fq 'https://herdr.dev/install.sh' "$DOWNLOADS"
  grep -Fq 'https://releases.herdr.dev/app/install.sh' "$DOWNLOADS"
  [ ! -s "$HERDR_CALLS" ]

  # Repeat runs and standalone installations must not download or launch Herdr.
  : >"$DOWNLOADS"
  TEST_PLATFORM="$platform" sh "$work/coding-agents.sh"
  [ ! -s "$DOWNLOADS" ]
  printf '#!/bin/sh\n# existing standalone Herdr\nexit 99\n' >"$HOME/.local/bin/herdr"
  TEST_PLATFORM="$platform" sh "$work/coding-agents.sh"
  [ ! -s "$DOWNLOADS" ]
  grep -Fq 'existing standalone Herdr' "$HOME/.local/bin/herdr"
  # Preserve a standalone GUI too; removing only it reinstalls only the GUI.
  printf '#!/bin/sh\n# existing standalone GUI\nexit 99\n' >"$HOME/.local/bin/herdr-app"
  TEST_PLATFORM="$platform" sh "$work/coding-agents.sh"
  [ ! -s "$DOWNLOADS" ]
  grep -Fq 'existing standalone GUI' "$HOME/.local/bin/herdr-app"
  rm "$HOME/.local/bin/herdr-app"
  TEST_PLATFORM="$platform" sh "$work/coding-agents.sh"
  grep -Fq 'https://releases.herdr.dev/app/install.sh' "$DOWNLOADS"
  if grep -Fq 'https://herdr.dev/install.sh' "$DOWNLOADS"; then exit 1; fi
  rm "$HOME/.local/bin/herdr" "$HOME/.local/bin/herdr-app"
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

# The GUI's download, installer, and missing-command failures must also fail bootstrap.
mkdir -p "$HOME/.local/bin"
cp "$HERDR_FIXTURE" "$HOME/.local/bin/herdr"
chmod +x "$HOME/.local/bin/herdr"
for failure in download installer missing-command; do
  status=0
  case $failure in
    download) TEST_PLATFORM=ubuntu APP_CURL_FAIL=1 sh "$work/coding-agents.sh" >"$work/app-failure" 2>&1 || status=$? ;;
    installer) TEST_PLATFORM=ubuntu APP_INSTALLER_FAIL=1 sh "$work/coding-agents.sh" >"$work/app-failure" 2>&1 || status=$? ;;
    missing-command) TEST_PLATFORM=ubuntu APP_NO_BINARY=1 sh "$work/coding-agents.sh" >"$work/app-failure" 2>&1 || status=$? ;;
  esac
  [ "$status" != 0 ]
  [ ! -e "$HOME/.local/bin/herdr-app" ]
  case $failure in
    download) grep -Fq 'failed to download the Herdr GUI installer' "$work/app-failure" ;;
    installer) grep -Fq 'Herdr GUI installer failed with status 42' "$work/app-failure" ;;
    missing-command) grep -Fq 'required command not found: herdr-app' "$work/app-failure" ;;
  esac
done

BOOTSTRAP_DIR="$work"
. "$work/lib.sh"
bootstrap_packages macos brew-formula agents | grep -Fxq herdr
bootstrap_packages macos brew-cask agents | grep -Fxq herdr-app
printf 'Herdr installation, existing-install, version, failure, Linux, and catalog checks passed.\n'

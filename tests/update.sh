#!/bin/sh
set -eu

repository=$(CDPATH= cd -- "$(dirname -- "$0")/.." && pwd)
work=$(mktemp -d "${TMPDIR:-/tmp}/dotfiles-update-test.XXXXXX")
trap 'rm -rf "$work"' EXIT HUP INT TERM
mkdir -p "$work/bootstrap" "$work/bin" "$work/home" "$work/state"
cp "$repository/bootstrap/lib.sh" "$repository/bootstrap/packages.sh" "$work/bootstrap/"
sed '$d' "$repository/update.sh" >"$work/update.sh"
printf '\ndetect_platform() { PLATFORM=${TEST_PLATFORM:-macos}; }\nmain "$@"\n' >>"$work/update.sh"
ln -s "$(command -v python3)" "$work/bin/python3"
ln -s "$(command -v jq)" "$work/bin/jq"
printf '#!/bin/sh\nprintf "1000\\n"\n' >"$work/bin/id"
chmod +x "$work/bin/id"

cat >"$work/tool" <<'EOF'
#!/bin/sh
set -eu
name=${0##*/}
printf '%s %s\n' "$name" "$*" >>"$CALLS"
# Every manager invocation must be detached, with authentication disabled.
[ "$CI" = 1 ]
[ "$GIT_TERMINAL_PROMPT" = 0 ]
[ "$SUDO_ASKPASS" = /bin/false ]
if ( : </dev/tty ) 2>/dev/null; then
  printf 'unexpected controlling terminal\n' >&2
  exit 90
fi
case $name in
  brew)
    [ "$HOMEBREW_NO_SUDO" = 1 ]
    [ "$HOMEBREW_NO_ASK" = 1 ]
    [ "$HOMEBREW_NO_INSTALL_CLEANUP" = 1 ]
    case $1 in
      --prefix) printf '%s/brew\n' "$HOME" ;;
      --repository) printf '%s/brew-repository\n' "$HOME" ;;
      update) [ "${REFRESH_FAIL:-0}" = 0 ] ;;
      upgrade)
        if [ "$2" = --help ]; then printf '%s\n' '--no-ask --no-quit'; exit; fi
        [ "$2" = --no-ask ]
        [ "$3" = --no-quit ]
        target=$5
        case $target in
          ghostty) exit 0 ;;
          maven) printf 'fixture download failure\n' >&2; exit 9 ;;
          auth-tool) printf 'requires sudo\n' >&2; exit 1 ;;
          forbidden-*) printf 'unselected package reached upgrade\n' >&2; exit 91 ;;
        esac
        jq --arg name "$target" '(.formulae[] | select(.full_name == $name)) |= (.outdated=false | .installed=[{version:"2.0.0"}]) | (.casks[] | select(.full_token == $name)) |= (.outdated=false | .installed="2.0.0")' "$STATE/brew.json" >"$STATE/next"
        mv "$STATE/next" "$STATE/brew.json"
        ;;
      info)
        if [ "${INVALID_AFTER:-0}" = 1 ] && [ "$3" != --installed ]; then
          printf '{}\n'
          exit 0
        fi
        if [ "$3" = --installed ]; then
          cat "$STATE/brew.json"
        else
          jq --arg name "$4" '{formulae:[.formulae[] | select(.full_name == $name)],casks:[.casks[] | select(.full_token == $name)]}' "$STATE/brew.json"
        fi
        ;;
      *) exit 92 ;;
    esac
    ;;
  npm)
    case $1 in
      prefix) printf '%s/npm-prefix\n' "$HOME" ;;
      list) cat "$STATE/npm.json" ;;
      outdated)
        if [ "${REGISTRY_AUTH:-0}" = 1 ]; then
          printf '{"error":{"code":"E401"}}\n'
          exit 1
        fi
        target=$6
        jq --arg name "$target" '.dependencies[$name] | if .wanted != null or .version == "1.0.0" then {($name):{current:.version,wanted:(.wanted // "2.0.0")}} else {} end' "$STATE/npm.json"
        exit 1
        ;;
      install)
        [ "$2" = --global ]
        [ "$3" = --prefix ]
        [ "$5" = --ignore-scripts ]
        target=${8%@*}
        jq --arg name "$target" '.dependencies[$name].version="2.0.0"' "$STATE/npm.json" >"$STATE/next"
        mv "$STATE/next" "$STATE/npm.json"
        ;;
      *) exit 93 ;;
    esac
    ;;
  mise)
    if [ "$1" = ls ]; then
      [ "$2" = --global ]
      cat "$STATE/mise.json"
    else
      [ "$1" = --yes ]
      [ "$2" = upgrade ]
      [ "$3" = --global ]
      [ "$4" = --no-prune ]
      [ "$5" != node ]
      jq --arg name "$5" '.[$name][0].version="2.0.0"' "$STATE/mise.json" >"$STATE/next"
      mv "$STATE/next" "$STATE/mise.json"
    fi
    ;;
  dpkg-query)
    case $1 in
      -W) printf 'git\tinstalled\nunrelated\tinstalled\nremoved\tconfig-files\n' ;;
      -S) exit 1 ;;
      *) exit 94 ;;
    esac
    ;;
  pacman) [ "$1" = -Qq ] && printf 'git\nunrelated\n' || exit 1 ;;
  rpm) [ "$1" = -qa ] && printf 'git\nunrelated\n' || exit 1 ;;
  sudo|apt-get|dnf|omarchy) printf 'privileged updater unexpectedly executed\n' >&2; exit 95 ;;
  *) exit 96 ;;
esac
EOF
chmod +x "$work/tool"
for tool in brew npm mise dpkg-query pacman rpm sudo apt-get dnf omarchy; do
  cp "$work/tool" "$work/bin/$tool"
done

cat >"$work/base-brew.json" <<'EOF'
{"formulae":[
 {"name":"jq","full_name":"jq","aliases":[],"installed":[{"version":"1.0.0"}],"outdated":true,"pinned":false},
 {"name":"unrelated","full_name":"unrelated","installed":[{"version":"1.0.0"}],"outdated":true,"pinned":false},
 {"name":"maven","full_name":"maven","installed":[{"version":"1.0.0"}],"outdated":true,"pinned":true}
],"casks":[
 {"token":"cursor","full_token":"cursor","installed":"1.0.0","outdated":true,"artifacts":[]},
 {"token":"1password","full_token":"1password","installed":"1.0.0","outdated":true,"artifacts":[{"pkg":["fixture.pkg"]}]},
 {"token":"ghostty","full_token":"ghostty","installed":"1.0.0","outdated":true,"artifacts":[]}
]}
EOF
mkdir -p "$work/home/npm-prefix/bin" "$work/home/npm-prefix/lib/node_modules" "$work/home/brew-repository/Library/Homebrew"
printf 'HOMEBREW_NO_SUDO:\n' >"$work/home/brew-repository/Library/Homebrew/env_config.rb"
export HOME="$work/home" STATE="$work/state" CALLS="$work/calls"
export PATH="$work/bin:/usr/bin:/bin"

reset_state() {
  unset REFRESH_FAIL TEST_PLATFORM INVALID_AFTER REGISTRY_AUTH
  : >"$CALLS"
  cp "$work/base-brew.json" "$STATE/brew.json"
  printf '{"dependencies":{"typescript":{"version":"1.0.0"},"unrelated-npm":{"version":"1.0.0"}}}\n' >"$STATE/npm.json"
  printf '{}\n' >"$STATE/mise.json"
}

assert_absent() {
  if grep -Eq "$1" "$2"; then
    printf 'unexpected match: %s in %s\n' "$1" "$2" >&2
    exit 1
  fi
}

run_expect() {
  expected=$1
  shift
  status=0
  sh "$work/update.sh" "$@" >"$work/output" 2>"$work/error" || status=$?
  if [ "$status" -ne "$expected" ]; then
    printf 'expected status %s, got %s\n' "$expected" "$status" >&2
    tail -50 "$work/output" "$work/error" >&2
    exit 1
  fi
}

reset_state
run_expect 2
# Both preinstalled tools and installed optional applications are selected.
grep -Fxq 'brew upgrade --no-ask --no-quit --formula jq' "$CALLS"
grep -Fxq 'brew upgrade --no-ask --no-quit --cask cursor' "$CALLS"
assert_absent 'upgrade .*(unrelated|maven|1password)' "$CALLS"
assert_absent '^npm .*unrelated-npm' "$CALLS"
grep -Eq '^SKIPPED +1password .*privileged' "$work/output"
grep -Eq '^SKIPPED +ghostty .*deferred' "$work/output"
grep -Eq '^UPDATED +typescript ' "$work/output"

reset_state
run_expect 2 --scope=all
grep -Fxq 'brew upgrade --no-ask --no-quit --formula unrelated' "$CALLS"
grep -Eq '^SKIPPED +unrelated-npm .*lifecycle' "$work/output"

reset_state
jq '.formulae[2].pinned=false' "$STATE/brew.json" >"$STATE/next"
mv "$STATE/next" "$STATE/brew.json"
run_expect 1 --scope bootstrap
grep -Eq '^FAILED +maven ' "$work/output"
# A failed formula must not stop subsequent independent updates.
grep -Eq '^UPDATED +cursor ' "$work/output"

reset_state
jq '.formulae += [{name:"auth-tool",full_name:"auth-tool",installed:[{version:"1.0.0"}],outdated:true,pinned:false}]' "$STATE/brew.json" >"$STATE/next"
mv "$STATE/next" "$STATE/brew.json"
run_expect 2 --scope all
grep -Eq '^SKIPPED +auth-tool .*authentication' "$work/output"

reset_state
REFRESH_FAIL=1 run_expect 1
assert_absent '^brew upgrade --no-ask' "$CALLS"

reset_state
: >"$HOME/brew-repository/Library/Homebrew/env_config.rb"
run_expect 2
grep -Eq '^SKIPPED +Homebrew .*no-sudo' "$work/output"
assert_absent '^brew update$' "$CALLS"
printf 'HOMEBREW_NO_SUDO:\n' >"$HOME/brew-repository/Library/Homebrew/env_config.rb"

reset_state
INVALID_AFTER=1 run_expect 1
grep -Eq '^FAILED +jq .*verify' "$work/output"
grep -Eq '^UPDATED +typescript ' "$work/output"

reset_state
REGISTRY_AUTH=1 run_expect 2
grep -Eq '^SKIPPED +typescript .*authentication' "$work/output"
assert_absent '^npm install' "$CALLS"

reset_state
mkdir -p "$HOME/runtime with spaces/lib/node_modules/typescript"
printf '{"node":[{"version":"1.0.0","install_path":"%s/runtime with spaces"}],"bun":[{"version":"1.0.0"}],"unrelated-mise":[{"version":"1.0.0"}]}\n' "$HOME" >"$STATE/mise.json"
run_expect 2
grep -Eq '^SKIPPED +mise:node .*migration-required' "$work/output"
grep -Fxq 'mise --yes upgrade --global --no-prune bun' "$CALLS"
assert_absent '^mise .*upgrade .*unrelated-mise' "$CALLS"

reset_state
printf '{"unrelated-mise":[{"version":"1.0.0"}]}\n' >"$STATE/mise.json"
run_expect 2 --scope=all
grep -Fxq 'mise --yes upgrade --global --no-prune unrelated-mise' "$CALLS"

reset_state
TEST_PLATFORM=ubuntu run_expect 2
grep -Eq '^SKIPPED +git .*administrator' "$work/output"
assert_absent '^SKIPPED +unrelated ' "$work/output"
assert_absent '^(sudo|apt-get|dnf|omarchy) ' "$CALLS"

reset_state
TEST_PLATFORM=arch run_expect 2 --scope=all
grep -Eq '^SKIPPED +unrelated .*administrator' "$work/output"
assert_absent '^pacman -S' "$CALLS"

reset_state
TEST_PLATFORM=fedora run_expect 2
grep -Eq '^SKIPPED +git .*administrator' "$work/output"
assert_absent '^(sudo|dnf) ' "$CALLS"

reset_state
TEST_PLATFORM=omarchy run_expect 2
grep -Eq '^SKIPPED +git .*administrator' "$work/output"
assert_absent '^omarchy ' "$CALLS"

reset_state
run_expect 3 --scope=invalid
[ ! -s "$CALLS" ]
run_expect 3 --scope
[ ! -s "$CALLS" ]

printf '#!/bin/sh\nprintf "0\\n"\n' >"$work/bin/id"
reset_state
run_expect 3
[ ! -s "$CALLS" ]
printf '#!/bin/sh\nprintf "1000\\n"\n' >"$work/bin/id"

# Package metadata owns pre-existing installations; never run a second native
# updater against a Homebrew/npm-owned executable.
reset_state
mkdir -p "$HOME/brew/Cellar/opencode/1/bin" "$HOME/npm-prefix/lib/node_modules/@openai/codex"
printf '#!/bin/sh\nexit 99\n' >"$HOME/brew/Cellar/opencode/1/bin/opencode"
printf '#!/bin/sh\nexit 99\n' >"$HOME/npm-prefix/lib/node_modules/@openai/codex/codex"
chmod +x "$HOME/brew/Cellar/opencode/1/bin/opencode" "$HOME/npm-prefix/lib/node_modules/@openai/codex/codex"
ln -s "$HOME/brew/Cellar/opencode/1/bin/opencode" "$work/bin/opencode"
ln -s "$HOME/npm-prefix/lib/node_modules/@openai/codex/codex" "$work/bin/codex"
jq '.formulae += [{name:"opencode",full_name:"opencode",installed:[{version:"1.0.0"}],outdated:true,pinned:false}]' "$STATE/brew.json" >"$STATE/next"
mv "$STATE/next" "$STATE/brew.json"
printf '{"dependencies":{"@openai/codex":{"version":"1.0.0"}}}\n' >"$STATE/npm.json"
run_expect 2
grep -Eq '^UPDATED +opencode ' "$work/output"
grep -Eq '^UPDATED +@openai/codex ' "$work/output"
assert_absent '^SKIPPED +(opencode|codex) ' "$work/output"
rm "$work/bin/opencode" "$work/bin/codex"

reset_state
printf '{"dependencies":{"typescript":{"version":"3.0.0","wanted":"2.0.0"}}}\n' >"$STATE/npm.json"
run_expect 2
grep -Eq '^SKIPPED +typescript .*downgrade' "$work/output"
assert_absent '^npm install' "$CALLS"

# A real managed entrypoint is updated without running the Pi installer or
# updating project configuration. Invalid markers must never trigger fallback.
reset_state
mkdir -p "$HOME/.pi/agent/bin" "$HOME/.pi/agent/install"
printf '{"kind":"pi-managed-install","schemaVersion":1,"layout":"releases-v1"}\n' >"$HOME/.pi/agent/install/managed-install.json"
printf '1.0.0\n' >"$STATE/pi-version"
cat >"$HOME/.pi/agent/bin/pi" <<'EOF'
#!/bin/sh
set -eu
if [ "$1" = --version ]; then
  cat "$STATE/pi-version"
else
  [ "$1" = update ]
  [ "$2" = --no-approve ]
  printf 'pi %s\n' "$*" >>"$CALLS"
  printf '2.0.0\n' >"$STATE/pi-version"
fi
EOF
chmod +x "$HOME/.pi/agent/bin/pi"
ln -s "$HOME/.pi/agent/bin/pi" "$work/bin/pi"
run_expect 2
grep -Eq '^UPDATED +pi +managed' "$work/output"
grep -Fxq 'pi update --no-approve' "$CALLS"
printf '{}\n' >"$HOME/.pi/agent/install/managed-install.json"
reset_state
run_expect 2
grep -Eq '^SKIPPED +pi .*unrecognized' "$work/output"
assert_absent '^pi update' "$CALLS"
rm "$work/bin/pi"

# Native agent updates stay on their existing installation method.
reset_state
mkdir -p "$HOME/.opencode/bin" "$HOME/.local/share/claude/versions"
cat >"$work/native-agent" <<'EOF'
#!/bin/sh
set -eu
if [ "$AGENT_NAME" = mise ] && [ "$1" = ls ]; then printf '{}\n'; exit 0; fi
if [ "$1" = --version ]; then
  if [ -f "$STATE/$AGENT_NAME-version" ]; then cat "$STATE/$AGENT_NAME-version"; else printf '1.0.0\n'; fi
else
  printf '%s %s\n' "$AGENT_NAME" "$*" >>"$CALLS"
  case $AGENT_NAME in
    claude) [ "$1" = update ] ;;
    opencode) [ "$1" = upgrade ] && [ "$2" = --method ] && [ "$3" = curl ] ;;
    mise) [ "$1" = self-update ] && [ "$2" = --yes ] && [ "$3" = --no-plugins ] ;;
  esac
  printf '2.0.0\n' >"$STATE/$AGENT_NAME-version"
fi
EOF
# Each executable sets its own identity before the shared fixture body.
for agent in claude opencode mise; do
  { printf '#!/bin/sh\nAGENT_NAME=%s\n' "$agent"; tail -n +2 "$work/native-agent"; } >"$work/$agent"
  chmod +x "$work/$agent"
done
cp "$work/claude" "$HOME/.local/share/claude/versions/fixture"
cp "$work/opencode" "$HOME/.opencode/bin/opencode"
mkdir -p "$HOME/.local/bin"
cp "$work/mise" "$HOME/.local/bin/mise"
ln -s "$HOME/.local/share/claude/versions/fixture" "$work/bin/claude"
run_expect 2
grep -Eq '^UPDATED +claude +native' "$work/output"
grep -Eq '^UPDATED +opencode +native' "$work/output"
grep -Fxq 'opencode upgrade --method curl' "$CALLS"
grep -Fxq 'mise self-update --yes --no-plugins' "$CALLS"
rm "$work/bin/claude" "$HOME/.opencode/bin/opencode" "$HOME/.local/bin/mise"

# Exercise the real checksum-verifying release downloader and atomic activation
# with local HTTP fixtures, including a tampered archive. No network is used.
reset_state
mkdir -p "$work/archive" "$HOME/.local/bin"
printf '#!/bin/sh\nprintf "new-release\\n"\n' >"$work/archive/lazygit"
chmod +x "$work/archive/lazygit"
tar -czf "$STATE/asset.tar.gz" -C "$work/archive" lazygit
if command -v sha256sum >/dev/null 2>&1; then
  checksum=$(sha256sum "$STATE/asset.tar.gz" | awk '{print $1}')
else
  checksum=$(shasum -a 256 "$STATE/asset.tar.gz" | awk '{print $1}')
  printf '#!/bin/sh\nexec /usr/bin/shasum -a 256 "$@"\n' >"$work/bin/sha256sum"
  chmod +x "$work/bin/sha256sum"
fi
printf '%s  lazygit_2.0.0_linux_x86_64.tar.gz\n' "$checksum" >"$STATE/checksums.txt"
cat >"$work/bin/curl" <<'EOF'
#!/bin/sh
set -eu
[ "$1" = -fsSL ]
url=$2
[ "$3" = -o ]
case $url in
  */releases/latest)
    printf '{"tag_name":"v2.0.0","assets":[{"name":"lazygit_2.0.0_linux_x86_64.tar.gz","browser_download_url":"https://fixture.invalid/asset"},{"name":"checksums.txt","browser_download_url":"https://fixture.invalid/checksums"}]}' >"$4"
    ;;
  */asset) cp "$STATE/asset.tar.gz" "$4" ;;
  */checksums) cp "$STATE/checksums.txt" "$4" ;;
  *) exit 97 ;;
esac
EOF
printf '#!/bin/sh\nprintf "x86_64\\n"\n' >"$work/bin/uname"
chmod +x "$work/bin/curl" "$work/bin/uname"
printf '#!/bin/sh\nprintf "old-release\\n"\n' >"$HOME/.local/bin/lazygit"
chmod +x "$HOME/.local/bin/lazygit"
TEST_PLATFORM=ubuntu run_expect 2
grep -Eq '^UPDATED +lazygit .*atomic' "$work/output"
[ "$("$HOME/.local/bin/lazygit")" = new-release ]
printf 'tampering\n' >>"$STATE/asset.tar.gz"
reset_state
TEST_PLATFORM=ubuntu run_expect 1
grep -Eq '^FAILED +lazygit ' "$work/output"
[ "$("$HOME/.local/bin/lazygit")" = new-release ]
rm "$HOME/.local/bin/lazygit"

# A fully current, empty optional set succeeds, rather than treating missing
# bootstrap tools as either installation requests or blocked updates.
reset_state
printf '{"formulae":[],"casks":[]}\n' >"$STATE/brew.json"
printf '{"dependencies":{}}\n' >"$STATE/npm.json"
rm "$work/bin/mise"
run_expect 0
grep -Fq '0 updated, 0 unchanged, 0 skipped, 0 failed' "$work/output"

# Check the shared package declarations still route to bootstrap's existing
# installers and preserve their package arguments.
(
  BOOTSTRAP_DIR="$repository/bootstrap"
  . "$BOOTSTRAP_DIR/lib.sh"
  PLATFORM=macos
  ensure_brew_formulas() { printf '%s\n' "$*"; }
  [ "$(ensure_bootstrap_packages brew-formula java)" = 'openjdk@25 maven gradle' ]
  [ "$(ensure_bootstrap_packages brew-formula javascript)" = 'node bun' ]
  ensure_brew_casks() { printf '%s\n' "$*"; }
  [ "$(ensure_bootstrap_packages brew-cask editors)" = 'intellij-idea visual-studio-code cursor zed' ]
  PLATFORM=ubuntu
  ensure_ubuntu_packages() { printf '%s\n' "$*"; }
  [ "$(ensure_bootstrap_packages system docker)" = 'docker.io docker-compose-v2 docker-buildx' ]
)
printf 'Update scope, unattended execution, ownership policies, pins, partial failures, platform skips, and shared catalog checks passed.\n'

#!/bin/sh

set -eu
set -f

BOOTSTRAP_DIR=$(CDPATH= cd -- "$(dirname -- "$0")/bootstrap" && pwd)
# shellcheck source=bootstrap/lib.sh
. "$BOOTSTRAP_DIR/lib.sh"

SCOPE=bootstrap
WORK=''
BREW_PREFIX=''
NPM_PREFIX=''
ACTIVATION_TEMP=''

cleanup() {
  if [ -n "$ACTIVATION_TEMP" ]; then rm -f "$ACTIVATION_TEMP"; fi
  rm -rf "$WORK"
}

usage() {
  printf '%s\n' \
    'Usage: update.sh [--scope=bootstrap|all]' \
    '' \
    'Update installed workstation tools without requesting authentication.' \
    'Default scope: bootstrap toolset, including installed optional apps.' \
    'All scope: installed packages in supported managers and recognized tools.' \
    'Requires Python 3 and jq. Never installs managers, invokes sudo, changes' \
    'project dependencies, migrates installations, or forces apps to quit.' \
    '' \
    'Exit status: 0 complete; 1 update failure; 2 skipped targets; 3 setup/usage error.'
}

setup_error() {
  printf 'error: %s\n' "$*" >&2
  exit 3
}

report() {
  printf '%-10s %-28s %s\n' "$1" "$2" "$3"
  printf '%s\t%s\t%s\n' "$1" "$2" "$3" >>"$WORK/results"
}

# A redirected stdin does not prevent /dev/tty prompts. A new session does.
# Authentication helpers are disabled too; no credentials or sudo are acquired.
unattended() {
  python3 - "$@" <<'PY'
import os
import signal
import subprocess
import sys

env = os.environ.copy()
env.update({
    "CI": "1", "GIT_TERMINAL_PROMPT": "0", "GIT_ASKPASS": "/bin/false",
    "SSH_ASKPASS": "/bin/false", "SSH_ASKPASS_REQUIRE": "never",
    "SUDO_ASKPASS": "/bin/false", "HOMEBREW_NO_ASK": "1",
    "HOMEBREW_NO_SUDO": "1", "HOMEBREW_NO_AUTO_UPDATE": "1",
    "HOMEBREW_NO_INSTALL_CLEANUP": "1", "HOMEBREW_NO_AUTOREMOVE": "1",
    "HOMEBREW_NO_UPGRADE_QUIT_CASKS": "1",
})
# Retain SSH routing/options, but never allow a credential/host-key prompt.
env["GIT_SSH_COMMAND"] = env.get("GIT_SSH_COMMAND", "ssh") + " -o BatchMode=yes -o StrictHostKeyChecking=yes"
try:
    child = subprocess.Popen(sys.argv[1:], stdin=subprocess.DEVNULL,
                             start_new_session=True, env=env)
except OSError as error:
    print(error, file=sys.stderr)
    sys.exit(1)

def forward_signal(number, _frame):
    try:
        os.killpg(child.pid, number)
    except ProcessLookupError:
        pass

for number in (signal.SIGINT, signal.SIGTERM, signal.SIGHUP):
    signal.signal(number, forward_signal)
status = child.wait()
sys.exit(status if status >= 0 else 128 - status)
PY
}

selected() {
  [ "$SCOPE" != all ] || return 0
  selection_platform=$PLATFORM
  # The same formula identities also apply to pre-existing Linuxbrew installs.
  case $1 in brew-*) selection_platform=macos ;; esac
  # Derive each immutable selection list once, not once per installed package.
  if [ ! -f "$WORK/catalog-$1" ]; then
    bootstrap_packages "$selection_platform" "$1" all >"$WORK/catalog-$1"
  fi
  grep -Fxq -- "$2" "$WORK/catalog-$1"
}

real_path() {
  python3 -c 'import os,sys; print(os.path.realpath(sys.argv[1]))' "$1"
}

# Inventory requests can need authentication too (for example a private npm
# registry). Keep that classification shared with update-command refusals.
report_command_failure() {
  failure_target=$1
  failure_message=$2
  shift 2
  if grep -Eiq 'untrusted|trust.*(required|approval)' "$@"; then
    report SKIPPED "$failure_target" 'tap or source trust requires separate approval'
  elif grep -Eiq 'requires? (sudo|root|.*password|.*administrator)|sudo.*(disabled|password|not permitted)|permission denied|EACCES|E401|ENEEDAUTH|authentication (required|failed)|terminal prompts disabled|could not read Username|host key verification failed' "$@"; then
    report SKIPPED "$failure_target" 'authentication or write permission required'
  else
    report FAILED "$failure_target" "$failure_message"
    # Logs are temporary and local; authentication diagnostics are not echoed.
    tail -n 10 "$@" >&2
  fi
}

run_update() {
  task_name=$1
  shift
  if unattended "$@" >"$WORK/task.log" 2>&1; then
    return 0
  else
    task_status=$?
  fi
  report_command_failure "$task_name" "command exited $task_status" "$WORK/task.log"
  return 1
}

update_homebrew() {
  command -v brew >/dev/null 2>&1 || return 0
  BREW_PREFIX=$(unattended brew --prefix) || { report FAILED Homebrew 'cannot read prefix'; return; }
  BREW_PREFIX=$(real_path "$BREW_PREFIX")
  # Environment variables unknown to an older brew are silently ignored. Check
  # the local implementation before relying on the documented no-sudo control.
  brew_repository=$(unattended brew --repository) || { report FAILED Homebrew 'cannot locate implementation'; return; }
  if ! grep -q 'HOMEBREW_NO_SUDO:' "$brew_repository/Library/Homebrew/env_config.rb" 2>/dev/null; then
    report SKIPPED Homebrew 'installed version lacks the no-sudo control'
    return
  fi
  if ! unattended brew upgrade --help >"$WORK/brew-help" 2>&1 ||
    ! grep -q -- '--no-ask' "$WORK/brew-help" || ! grep -q -- '--no-quit' "$WORK/brew-help"; then
    report SKIPPED Homebrew 'installed version lacks required unattended flags'
    return
  fi
  run_update Homebrew brew update || return 0
  if ! unattended brew info --json=v2 --installed >"$WORK/brew.json" 2>"$WORK/query.err" ||
    ! jq -e '(.formulae | type == "array") and (.casks | type == "array")' "$WORK/brew.json" >/dev/null 2>&1; then
    report_command_failure Homebrew 'cannot read installed-package metadata' "$WORK/query.err"
    return
  fi
  if ! jq -c '
    (.formulae[] | {kind:"formula", name:.full_name,
      names:([.name,.full_name] + (.aliases // []) + (.oldnames // [])),
      outdated:.outdated, pinned:.pinned, privileged:false}),
    (.casks[] | {kind:"cask", name:.full_token, names:[.token,.full_token],
      outdated:.outdated, pinned:(.pinned // false),
      privileged:any(.artifacts[]?; has("pkg") or has("installer"))})
  ' "$WORK/brew.json" >"$WORK/brew-targets"; then
    report FAILED Homebrew 'invalid installed-package metadata'
    return
  fi
  while IFS= read -r brew_row; do
    brew_kind=$(printf '%s\n' "$brew_row" | jq -r .kind)
    brew_name=$(printf '%s\n' "$brew_row" | jq -r .name)
    brew_selected=false
    for brew_alias in $(printf '%s\n' "$brew_row" | jq -r '.names[]'); do
      if selected "brew-$brew_kind" "$brew_alias"; then brew_selected=true; break; fi
    done
    [ "$brew_selected" = true ] || continue
    if [ "$(printf '%s\n' "$brew_row" | jq -r .pinned)" = true ]; then
      report UNCHANGED "$brew_name" 'Homebrew pin preserved'
    elif [ "$(printf '%s\n' "$brew_row" | jq -r .outdated)" != true ]; then
      report UNCHANGED "$brew_name" 'Homebrew reports no eligible update'
    elif [ "$(printf '%s\n' "$brew_row" | jq -r .privileged)" = true ]; then
      report SKIPPED "$brew_name" 'cask installer requires privileged or interactive execution'
    elif run_update "$brew_name" brew upgrade --no-ask --no-quit "--$brew_kind" "$brew_name"; then
      # --no-quit may defer a running cask with a successful exit status.
      if ! unattended brew info --json=v2 "--$brew_kind" "$brew_name" >"$WORK/brew-after.json" ||
        ! jq -e '(.formulae | type == "array") and (.casks | type == "array") and ((.formulae + .casks) | length > 0)' "$WORK/brew-after.json" >/dev/null 2>&1; then
        report FAILED "$brew_name" 'cannot verify updated package'
      elif jq -e '[.formulae[], .casks[]] | any(.outdated == true)' "$WORK/brew-after.json" >/dev/null; then
        report SKIPPED "$brew_name" 'update deferred (for example, app is running)'
      else
        report UPDATED "$brew_name" 'Homebrew'
      fi
    fi
  done <"$WORK/brew-targets"
}

update_system_packages() {
  case $PLATFORM in
    ubuntu)
      unattended dpkg-query -W '-f=${binary:Package}\t${db:Status-Status}\n' >"$WORK/system.raw" || {
        report FAILED APT 'cannot inventory installed packages'; return;
      }
      awk '$2 == "installed" { sub(/:.*/, "", $1); print $1 }' "$WORK/system.raw" >"$WORK/system"
      ;;
    fedora) unattended rpm -qa --qf '%{NAME}\n' >"$WORK/system" || { report FAILED DNF 'cannot inventory installed packages'; return; } ;;
    arch|omarchy) unattended pacman -Qq >"$WORK/system" || { report FAILED pacman 'cannot inventory installed packages'; return; } ;;
    *) return 0 ;;
  esac
  while IFS= read -r system_name; do
    selected system "$system_name" || continue
    report SKIPPED "$system_name" 'system package requires administrator privileges; use the platform updater'
  done <"$WORK/system"
  if [ "$PLATFORM" = ubuntu ] && command -v snap >/dev/null 2>&1; then
    if unattended snap list >"$WORK/snap" 2>/dev/null; then
      awk 'NR > 1 { print $1 }' "$WORK/snap" | while IFS= read -r snap_name; do
        if [ "$SCOPE" = all ] || [ "$snap_name" = glab ]; then
          report SKIPPED "snap:$snap_name" 'system-managed refresh requires administrator privileges'
        fi
      done
    else
      report FAILED snap 'cannot inventory installed packages'
    fi
  fi
}

update_mise() {
  command -v mise >/dev/null 2>&1 || return 0
  if ! unattended mise ls --global --installed --json >"$WORK/mise.json" 2>"$WORK/query.err" ||
    ! jq -e 'type == "object" and all(.[]; type == "array")' "$WORK/mise.json" >/dev/null 2>&1; then
    report_command_failure mise 'cannot read global installed-tool metadata' "$WORK/query.err"
    return
  fi
  jq -r 'keys[]' "$WORK/mise.json" >"$WORK/mise-targets"
  while IFS= read -r mise_name; do
    selected mise "$mise_name" || continue
    # Do not select missing tool requests or project configuration. Explicit
    # global mode preserves configured ranges and pins; never use --bump.
    if [ "$mise_name" = node ] && jq -e '.node[] | select(.install_path != null)' "$WORK/mise.json" >/dev/null; then
      mise_has_globals=false
      jq -r '.node[].install_path // empty' "$WORK/mise.json" >"$WORK/mise-node-paths"
      while IFS= read -r mise_node_path; do
        if [ -d "$mise_node_path/lib/node_modules" ] &&
          find "$mise_node_path/lib/node_modules" -mindepth 1 -maxdepth 1 ! -name npm ! -name corepack -print | grep -q .; then
          mise_has_globals=true
        fi
      done <"$WORK/mise-node-paths"
      if [ "$mise_has_globals" = true ]; then
        report SKIPPED mise:node 'migration-required: Node upgrade could strand global npm tools'
        continue
      fi
    fi
    if run_update "mise:$mise_name" mise --yes upgrade --global --no-prune "$mise_name"; then
      if unattended mise ls --global --installed --json >"$WORK/mise-after.json" &&
        jq -e --arg name "$mise_name" '.[$name] | type == "array"' "$WORK/mise-after.json" >/dev/null 2>&1; then
        mise_before=$(jq -c --arg name "$mise_name" '.[$name] | map(.version) | sort' "$WORK/mise.json")
        mise_after=$(jq -c --arg name "$mise_name" '.[$name] | map(.version) | sort' "$WORK/mise-after.json")
        if [ "$mise_before" = "$mise_after" ]; then
          report UNCHANGED "mise:$mise_name" 'configured version constraint preserved'
        else
          report UPDATED "mise:$mise_name" 'global configuration only'
        fi
      else
        report FAILED "mise:$mise_name" 'cannot verify updated tool'
      fi
    fi
  done <"$WORK/mise-targets"
}

update_npm_prefix() {
  npm_command=$1
  npm_prefix=$2
  if ! unattended "$npm_command" list --global --prefix "$npm_prefix" --depth=0 --json >"$WORK/npm.json" 2>"$WORK/npm.err"; then
    # npm ls can return nonzero for a usable tree containing extraneous entries.
    if ! jq -e '.dependencies | type == "object"' "$WORK/npm.json" >/dev/null 2>&1; then
      report_command_failure "npm:$npm_prefix" 'cannot inventory global packages' "$WORK/npm.err"
      return
    fi
  fi
  if ! jq -e 'type == "object" and (has("error") | not) and ((.dependencies // {}) | type == "object")' "$WORK/npm.json" >/dev/null 2>&1; then
    report FAILED "npm:$npm_prefix" 'invalid global-package metadata'
    return
  fi
  jq -c '.dependencies // {} | to_entries[]' "$WORK/npm.json" >"$WORK/npm-targets"
  while IFS= read -r npm_row; do
    npm_name=$(printf '%s\n' "$npm_row" | jq -r .key)
    selected npm "$npm_name" || continue
    if [ "$(printf '%s\n' "$npm_row" | jq -r '.value.link // false')" = true ] ||
      [ -L "$npm_prefix/lib/node_modules/$npm_name" ]; then
      report SKIPPED "$npm_name" 'linked global package; source checkout left untouched'
      continue
    fi
    if [ ! -w "$npm_prefix/lib/node_modules" ] || [ ! -w "$npm_prefix/bin" ]; then
      report SKIPPED "$npm_name" 'npm prefix requires administrator write access'
      continue
    fi
    if ! unattended "$npm_command" outdated --global --prefix "$npm_prefix" --json "$npm_name" >"$WORK/npm-outdated.json" 2>"$WORK/npm.err"; then
      # Exit 1 is the normal npm-outdated result when an update is available.
      if ! jq -e --arg name "$npm_name" '.[$name].current and .[$name].wanted' "$WORK/npm-outdated.json" >/dev/null 2>&1; then
        report_command_failure "$npm_name" 'cannot determine npm update version' "$WORK/npm.err" "$WORK/npm-outdated.json"
        continue
      fi
    fi
    if ! jq -e 'type == "object"' "$WORK/npm-outdated.json" >/dev/null 2>&1; then
      report FAILED "$npm_name" 'invalid npm update metadata'
      continue
    fi
    npm_current=$(jq -r --arg name "$npm_name" '.[$name].current // empty' "$WORK/npm-outdated.json")
    npm_wanted=$(jq -r --arg name "$npm_name" '.[$name].wanted // empty' "$WORK/npm-outdated.json")
    if [ -z "$npm_wanted" ] || [ "$npm_current" = "$npm_wanted" ]; then
      report UNCHANGED "$npm_name" 'npm reports no eligible update'
      continue
    fi
    # npm update -g can downgrade packages newer than its wanted dist-tag.
    if ! python3 - "$npm_current" "$npm_wanted" <<'PY'
import re
import sys

def stable(value):
    match = re.fullmatch(r"(\d+)\.(\d+)\.(\d+)", value)
    return tuple(map(int, match.groups())) if match else None

current, wanted = map(stable, sys.argv[1:])
sys.exit(0 if current is not None and wanted is not None and wanted > current else 1)
PY
    then
      report SKIPPED "$npm_name" 'downgrade or prerelease/channel change not authorized'
      continue
    fi
    # Bootstrap's reviewed CLI packages support --ignore-scripts. Unknown npm
    # packages may need lifecycle scripts: do not silently install broken tools
    # or allow arbitrary installers to open GUI authentication dialogs.
    case $npm_name in
      typescript|typescript-language-server|tsx|@openai/codex|@earendil-works/pi-coding-agent) ;;
      *)
        report SKIPPED "$npm_name" 'unreviewed npm lifecycle requirements; no safe unattended adapter'
        continue
        ;;
    esac
    if run_update "$npm_name" "$npm_command" install --global --prefix "$npm_prefix" --ignore-scripts --no-fund --no-audit "$npm_name@$npm_wanted"; then
      if unattended "$npm_command" list --global --prefix "$npm_prefix" --depth=0 --json "$npm_name" >"$WORK/npm-after.json" &&
        [ "$(jq -r --arg name "$npm_name" '.dependencies[$name].version' "$WORK/npm-after.json")" = "$npm_wanted" ]; then
        report UPDATED "$npm_name" "npm ($npm_prefix)"
      else
        report FAILED "$npm_name" 'installed version did not match requested update'
      fi
    fi
  done <"$WORK/npm-targets"
}

update_npm() {
  command -v npm >/dev/null 2>&1 || return 0
  NPM_PREFIX=$(unattended npm prefix --global) || { report FAILED npm 'cannot read global prefix'; return; }
  NPM_PREFIX=$(real_path "$NPM_PREFIX")
  update_npm_prefix "$(command -v npm)" "$NPM_PREFIX"
  # mise runtime prefixes can contain their own global tools. Use the matching
  # runtime's npm, not whichever Node is first on the calling shell's PATH.
  if [ -s "$WORK/mise.json" ]; then
    jq -r '.node[]?.install_path // empty' "$WORK/mise.json" >"$WORK/node-paths"
    while IFS= read -r node_path; do
      node_path=$(real_path "$node_path")
      [ "$node_path" != "$NPM_PREFIX" ] && [ -x "$node_path/bin/npm" ] || continue
      (PATH="$node_path/bin:$PATH"; export PATH; update_npm_prefix "$node_path/bin/npm" "$node_path")
    done <"$WORK/node-paths"
  fi
}

package_owned_path() {
  owned_path=$1
  case $owned_path in
    "$NPM_PREFIX"/lib/node_modules/*) [ -n "$NPM_PREFIX" ] && return 0 ;;
  esac
  if [ -s "$WORK/mise.json" ]; then
    jq -r '.[][] | .install_path // empty' "$WORK/mise.json" >"$WORK/mise-paths"
    while IFS= read -r owned_root; do
      owned_root=$(real_path "$owned_root")
      case $owned_path in "$owned_root"/*) return 0 ;; esac
    done <"$WORK/mise-paths"
  fi
  case $owned_path in
    "$BREW_PREFIX"/Cellar/*|"$BREW_PREFIX"/Caskroom/*) [ -n "$BREW_PREFIX" ] && return 0 ;;
  esac
  case $PLATFORM in
    ubuntu) unattended dpkg-query -S "$owned_path" >/dev/null 2>&1 && return 0 ;;
    fedora) unattended rpm -qf "$owned_path" >/dev/null 2>&1 && return 0 ;;
    arch|omarchy) unattended pacman -Qo "$owned_path" >/dev/null 2>&1 && return 0 ;;
  esac
  return 1
}

update_archive_tool() {
  archive_command=$1
  archive_repository=$2
  archive_prefix=$3
  archive_suffix=$4
  archive_destination="$HOME/.local/bin/$archive_command"
  if [ -L "$archive_destination" ] || [ ! -w "$archive_destination" ] || [ ! -w "$HOME/.local/bin" ]; then
    report SKIPPED "$archive_command" 'unrecognized or non-writable release destination'
    return
  fi
  if ! command -v curl >/dev/null 2>&1 || ! command -v sha256sum >/dev/null 2>&1; then
    report SKIPPED "$archive_command" 'curl and sha256sum required for verified release updates'
    return
  fi
  mkdir -p "$WORK/release-home"
  # Reuse bootstrap's checksum-verifying downloader, staging under a disposable
  # HOME. It cannot overwrite the live binary before verification succeeds.
  if run_update "$archive_command" env HOME="$WORK/release-home" sh -eu -c '
    BOOTSTRAP_DIR=$1
    . "$BOOTSTRAP_DIR/lib.sh"
    install_github_release_archive "$2" "$3" "$4" "$5" "$2"
  ' sh "$BOOTSTRAP_DIR" "$archive_command" "$archive_repository" "$archive_prefix" "$archive_suffix"; then
    archive_staged="$WORK/release-home/.local/bin/$archive_command"
    if cmp -s "$archive_staged" "$archive_destination"; then
      report UNCHANGED "$archive_command" 'matches checksum-verified release'
    else
      ACTIVATION_TEMP=$(mktemp "$HOME/.local/bin/.$archive_command-update.XXXXXX") || {
        report FAILED "$archive_command" 'cannot stage atomic replacement'; return;
      }
      if cp "$archive_staged" "$ACTIVATION_TEMP" && chmod 755 "$ACTIVATION_TEMP" && mv -f "$ACTIVATION_TEMP" "$archive_destination"; then
        report UPDATED "$archive_command" 'checksum-verified release; atomic replacement'
      else
        rm -f "$ACTIVATION_TEMP"
        report FAILED "$archive_command" 'could not activate staged release'
      fi
      ACTIVATION_TEMP=''
    fi
  fi
}

update_native_cli() {
  cli_name=$1
  cli_owner=$2
  cli_command=$3
  shift 3
  cli_before=$(unattended "$cli_command" --version) || { report FAILED "$cli_name" 'cannot read installed version'; return; }
  if run_update "$cli_name" "$cli_command" "$@"; then
    cli_after=$(unattended "$cli_command" --version) || { report FAILED "$cli_name" 'cannot verify updated version'; return; }
    if [ "$cli_before" = "$cli_after" ]; then
      report UNCHANGED "$cli_name" "$cli_owner"
    else
      report UPDATED "$cli_name" "$cli_owner"
    fi
  fi
}

update_standalone_tools() {
  native_agent_dir=$(real_path "${PI_CODING_AGENT_DIR:-$HOME/.pi/agent}")
  native_bin_dir=$(real_path "$HOME/.local/bin")
  native_claude_dir=$(real_path "$HOME/.local/share/claude/versions")
  native_opencode_dir=$(real_path "$HOME/.opencode/bin")
  for native_name in claude codex opencode pi starship lazygit mdc revdiff nvim yazi ya kubectl helm minikube op mise; do
    native_command=$(command -v "$native_name" 2>/dev/null) || continue
    native_path=$(real_path "$native_command")
    package_owned_path "$native_path" && continue
    case "$native_name:$native_path" in
      "claude:$native_claude_dir/"*)
        if [ ! -w "$HOME/.local/share/claude/versions" ]; then
          report SKIPPED claude 'native installation is not writable'
          continue
        fi
        update_native_cli claude 'native installation' "$native_command" update
        ;;
      "opencode:$native_opencode_dir/opencode")
        if [ -w "$native_opencode_dir" ] && [ -w "$native_path" ]; then
          update_native_cli opencode 'native installation' "$native_command" upgrade --method curl
        else
          report SKIPPED opencode 'native installation is not writable'
        fi
        ;;
      "mise:$native_bin_dir/mise")
        if [ -w "$native_bin_dir" ] && [ -w "$native_path" ]; then
          update_native_cli mise 'native installation (plugins unchanged)' "$native_command" self-update --yes --no-plugins
        else
          report SKIPPED mise 'native installation is not writable'
        fi
        ;;
      "pi:$native_agent_dir/bin/pi")
        pi_root="$native_agent_dir/install"
        if [ -w "$pi_root" ] && jq -e '.kind == "pi-managed-install" and .schemaVersion == 1 and .layout == "releases-v1"' "$pi_root/managed-install.json" >/dev/null 2>&1; then
          update_native_cli pi 'managed installation' "$native_command" update --no-approve
        else
          report SKIPPED pi 'managed installation is unrecognized or not writable'
        fi
        ;;
      "lazygit:$native_bin_dir/lazygit"|"mdc:$native_bin_dir/mdc"|"revdiff:$native_bin_dir/revdiff")
        [ "$PLATFORM" != macos ] || { report SKIPPED "$native_name" 'standalone macOS release adapter not established'; continue; }
        case $(uname -m) in
          x86_64|amd64) archive_arch=amd64; lazygit_arch=x86_64 ;;
          aarch64|arm64) archive_arch=arm64; lazygit_arch=arm64 ;;
          *) report SKIPPED "$native_name" 'unsupported release architecture'; continue ;;
        esac
        case $native_name in
          lazygit) update_archive_tool lazygit jesseduffield/lazygit lazygit_ "_linux_$lazygit_arch.tar.gz" ;;
          mdc) update_archive_tool mdc kooler/MiddayCommander MiddayCommander_ "_linux_$archive_arch.tar.gz" ;;
          revdiff) update_archive_tool revdiff umputun/revdiff revdiff_ "_linux_$archive_arch.tar.gz" ;;
        esac
        ;;
      *) report SKIPPED "$native_name" 'standalone installation: safe unattended update adapter not established' ;;
    esac
  done
  if [ -d /opt/1Password ] || [ -d "$HOME/Applications/1Password.app" ]; then
    report SKIPPED '1Password desktop' 'use its existing app/package updater; no unattended vendor reinstallation'
  fi
  for manual_fonts in SourceCodePro FiraCodeNerdFont NerdFontsSymbolsOnly; do
    if [ -d "${XDG_DATA_HOME:-$HOME/.local/share}/fonts/$manual_fonts" ]; then
      report SKIPPED "$manual_fonts" 'manual font release; configured pin/files left untouched'
    fi
  done
}

main() {
  while [ "$#" -gt 0 ]; do
    case $1 in
      --scope=*) SCOPE=${1#*=} ;;
      --scope) [ "$#" -ge 2 ] || setup_error 'missing --scope value'; shift; SCOPE=$1 ;;
      -h|--help) usage; exit 0 ;;
      *) setup_error "unknown option: $1" ;;
    esac
    shift
  done
  case $SCOPE in bootstrap|all) ;; *) setup_error "unsupported scope: $SCOPE" ;; esac
  [ "$(id -u)" -ne 0 ] || setup_error 'run as your normal user, not root'
  for required in python3 jq; do
    command -v "$required" >/dev/null 2>&1 || setup_error "$required is required (not installed automatically)"
  done
  PLATFORM=$(detect_platform; printf '%s' "$PLATFORM") || setup_error 'unsupported platform'
  WORK=$(mktemp -d "${TMPDIR:-/tmp}/dotfiles-update.XXXXXX") || setup_error 'cannot create temporary workspace'
  trap cleanup EXIT
  trap 'exit 130' INT
  trap 'exit 143' HUP TERM
  : >"$WORK/results"
  # Never inherit a caller's project configuration or trust it during updates.
  cd "$WORK"
  printf 'Updating scope=%s on %s (unattended; no sudo)\n\n' "$SCOPE" "$PLATFORM"
  update_homebrew
  update_system_packages
  update_mise
  update_npm
  update_standalone_tools
  printf '\n'
  awk -F '\t' '{ counts[$1]++ } END { printf "Summary: %d updated, %d unchanged, %d skipped, %d failed\n", counts["UPDATED"], counts["UNCHANGED"], counts["SKIPPED"], counts["FAILED"] }' "$WORK/results"
  if grep -q '^FAILED' "$WORK/results"; then exit 1; fi
  if grep -q '^SKIPPED' "$WORK/results"; then exit 2; fi
}

main "$@"

#!/bin/sh

set -eu

BOOTSTRAP_DIR=$(CDPATH= cd -- "$(dirname -- "$0")" && pwd)
# shellcheck source=lib.sh
. "$BOOTSTRAP_DIR/lib.sh"

HARNESS_DIR="$HOME/code/harness"
HARNESS_HTTPS_URL=https://github.com/drafael/coding-harness.git
HARNESS_SSH_URL=git@github.com:drafael/coding-harness.git
REVDIFF_REPOSITORY=umputun/revdiff
REVDIFF_URL=https://github.com/umputun/revdiff

usage() {
  printf '%s\n' \
    'Usage: coding-agents.sh' \
    '' \
    'Install missing coding-agent tools, RevDiff integrations, and shared harness configuration.'
}

ensure_javascript_prerequisite() {
  if command -v npm >/dev/null 2>&1; then
    return
  fi
  info 'JavaScript tooling is required for npm-based coding agents'
  "$BOOTSTRAP_DIR/javascript.sh"
  refresh_standard_paths
  require_command npm
}

ensure_git() {
  if command -v git >/dev/null 2>&1; then
    return
  fi

  case $PLATFORM in
    macos) ensure_brew_formulas git ;;
    ubuntu) ensure_ubuntu_packages git ;;
    arch) ensure_arch_packages git ;;
    omarchy) ensure_omarchy_packages git ;;
  esac
  require_command git
}

harness_origin_is_expected() {
  case $1 in
    https://github.com/drafael/coding-harness|https://github.com/drafael/coding-harness.git|git@github.com:drafael/coding-harness|git@github.com:drafael/coding-harness.git|ssh://git@github.com/drafael/coding-harness|ssh://git@github.com/drafael/coding-harness.git)
      return 0
      ;;
    *) return 1 ;;
  esac
}

clone_harness() {
  mkdir -p "$(dirname -- "$HARNESS_DIR")"
  ssh_command='ssh -o BatchMode=yes -o ConnectTimeout=5'
  if GIT_SSH_COMMAND=$ssh_command git ls-remote "$HARNESS_SSH_URL" HEAD >/dev/null 2>&1; then
    info 'Cloning coding harness over SSH'
    GIT_SSH_COMMAND=$ssh_command git clone "$HARNESS_SSH_URL" "$HARNESS_DIR"
  else
    warn 'GitHub SSH access is unavailable; cloning the coding harness over HTTPS'
    git clone "$HARNESS_HTTPS_URL" "$HARNESS_DIR"
  fi
}

ensure_harness_checkout() {
  ensure_git
  if [ -e "$HARNESS_DIR" ] || [ -L "$HARNESS_DIR" ]; then
    [ -d "$HARNESS_DIR/.git" ] || fail "$HARNESS_DIR exists but is not a Git checkout"
    harness_origin=$(git -C "$HARNESS_DIR" remote get-url origin 2>/dev/null || true)
    harness_origin_is_expected "$harness_origin" ||
      fail "$HARNESS_DIR has unexpected origin: ${harness_origin:-none}"
  else
    clone_harness
  fi

  [ -d "$HARNESS_DIR/skills" ] || fail "coding harness skills directory not found: $HARNESS_DIR/skills"
  for harness_directory in themes prompts extensions; do
    [ -d "$HARNESS_DIR/.pi/agent/$harness_directory" ] ||
      fail "coding harness directory not found: $HARNESS_DIR/.pi/agent/$harness_directory"
  done
  [ -f "$HARNESS_DIR/AGENTS.md" ] || fail "coding harness file not found: $HARNESS_DIR/AGENTS.md"
  [ -f "$HARNESS_DIR/CLAUDE.md" ] || fail "coding harness file not found: $HARNESS_DIR/CLAUDE.md"
}

link_harness_configuration() {
  info 'Linking coding harness configuration'
  link_path_resolved "$HARNESS_DIR/skills" "$HOME/.agents/skills"
  link_path_resolved "$HARNESS_DIR/skills" "$HOME/.claude/skills"
  link_path_resolved "$HARNESS_DIR/.pi/agent/themes" "$HOME/.pi/agent/themes"
  link_path_resolved "$HARNESS_DIR/.pi/agent/prompts" "$HOME/.pi/agent/prompts"
  link_path_resolved "$HARNESS_DIR/.pi/agent/extensions" "$HOME/.pi/agent/extensions"
  link_path_resolved "$HARNESS_DIR/AGENTS.md" "$HOME/.pi/agent/AGENTS.md"
  link_path_resolved "$HARNESS_DIR/AGENTS.md" "$HOME/.agents/AGENTS.md"
  link_path_resolved "$HARNESS_DIR/CLAUDE.md" "$HOME/.claude/CLAUDE.md"
}

provision_harness() {
  ensure_harness_checkout
  link_harness_configuration
  if [ -n "$BACKUP_DIR" ]; then
    printf 'Existing harness configuration was saved under %s\n' "$BACKUP_DIR"
  fi
}

install_agents() {
  if [ "$PLATFORM" = omarchy ]; then
    info 'Keeping Omarchy coding-agent launchers'
    command -v codex >/dev/null 2>&1 || omarchy-mise-install codex
    return
  fi

  ensure_curl
  ensure_javascript_prerequisite

  if ! command -v claude >/dev/null 2>&1; then
    download_installer 'Claude Code' /bin/bash https://claude.ai/install.sh
  fi

  if ! command -v opencode >/dev/null 2>&1; then
    download_installer OpenCode /bin/bash https://opencode.ai/install --no-modify-path
  fi

  if ! command -v pi >/dev/null 2>&1; then
    info 'Installing Pi'
    npm install --global --ignore-scripts --min-release-age=0 --no-fund --no-audit @earendil-works/pi-coding-agent@latest
    reshim_mise_if_available
  fi

  if ! command -v codex >/dev/null 2>&1; then
    info 'Installing Codex CLI'
    npm install --global @openai/codex@latest
    reshim_mise_if_available
  fi
}

ensure_revdiff_prerequisites() {
  ensure_curl
  case $PLATFORM in
    macos) ensure_brew_formulas jq ;;
    ubuntu) ensure_ubuntu_packages jq tar ;;
    arch) ensure_arch_packages jq tar ;;
    omarchy) ensure_omarchy_packages jq tar ;;
  esac
}

install_revdiff() {
  if command -v revdiff >/dev/null 2>&1; then
    return
  fi

  ensure_revdiff_prerequisites
  if [ "$PLATFORM" = macos ]; then
    ensure_brew_formulas umputun/apps/revdiff
  else
    case $(uname -m) in
      x86_64|amd64) release_arch=amd64 ;;
      aarch64|arm64) release_arch=arm64 ;;
      *) fail "RevDiff does not publish a supported Linux archive for $(uname -m)" ;;
    esac
    install_github_release_archive RevDiff "$REVDIFF_REPOSITORY" revdiff_ "_linux_${release_arch}.tar.gz" revdiff
  fi

  refresh_standard_paths
  require_command revdiff
}

command_output_contains() {
  expected_text=$1
  shift
  "$@" 2>/dev/null | grep -Fq "$expected_text"
}

install_claude_revdiff_plugins() {
  if ! command_output_contains "$REVDIFF_REPOSITORY" claude plugin marketplace list --json; then
    info 'Adding the RevDiff marketplace to Claude Code'
    claude plugin marketplace add --scope user "$REVDIFF_REPOSITORY"
  fi

  for plugin_name in revdiff revdiff-planning; do
    plugin_id="$plugin_name@revdiff"
    if ! command_output_contains "$plugin_id" claude plugin list --json; then
      info "Installing $plugin_id for Claude Code"
      claude plugin install --scope user --yes "$plugin_id"
    fi
  done
}

install_codex_revdiff_plugins() {
  if ! command_output_contains "$REVDIFF_REPOSITORY" codex plugin marketplace list --json; then
    info 'Adding the RevDiff marketplace to Codex'
    codex plugin marketplace add "$REVDIFF_REPOSITORY"
  fi

  for plugin_name in revdiff revdiff-planning; do
    plugin_id="$plugin_name@revdiff"
    if ! command_output_contains "$plugin_id" codex plugin list --json; then
      info "Installing $plugin_id for Codex"
      codex plugin add "$plugin_id"
    fi
  done
}

install_pi_package() {
  package_label=$1
  package_name=$2
  package_source=$3
  if command_output_contains "$package_name" pi list; then
    return
  fi
  info "Installing $package_label for Pi"
  pi install "$package_source"
}

install_pi_packages() {
  install_pi_package RevDiff revdiff "$REVDIFF_URL"
  install_pi_package pi-subagents pi-subagents npm:pi-subagents
  install_pi_package pi-web-access pi-web-access npm:pi-web-access
  install_pi_package pi-intercom pi-intercom npm:pi-intercom
}

opencode_revdiff_is_installed() {
  opencode_config_dir="$HOME/.config/opencode"
  for relative_path in \
    commands/revdiff.md \
    tools/revdiff.ts \
    tools/launch-revdiff.sh \
    plugins/revdiff-plan-review.ts \
    plugins/launch-plan-review.sh; do
    [ -f "$opencode_config_dir/$relative_path" ] || return 1
  done

  grep -Fq './plugins/revdiff-plan-review.ts' "$opencode_config_dir/opencode.json" 2>/dev/null ||
    grep -Fq './plugins/revdiff-plan-review.ts' "$opencode_config_dir/opencode.jsonc" 2>/dev/null
}

install_opencode_revdiff_integration() {
  if opencode_revdiff_is_installed; then
    return
  fi

  temp_dir=$(mktemp -d "${TMPDIR:-/tmp}/revdiff-plugin.XXXXXX")
  info 'Installing the RevDiff integration for OpenCode'
  if git clone --depth 1 "$REVDIFF_URL.git" "$temp_dir/revdiff" &&
    bash "$temp_dir/revdiff/plugins/opencode/setup.sh" &&
    opencode_revdiff_is_installed; then
    rm -rf "$temp_dir"
  else
    status=$?
    rm -rf "$temp_dir"
    fail "OpenCode RevDiff integration failed with status $status"
  fi
}

install_revdiff_integrations() {
  ensure_revdiff_prerequisites
  ensure_git
  for agent in claude codex opencode pi; do
    require_command "$agent"
  done

  install_claude_revdiff_plugins
  install_codex_revdiff_plugins
  install_pi_packages
  install_opencode_revdiff_integration
}

main() {
  case ${1:-} in
    -h|--help) usage; exit 0 ;;
    '') ;;
    *) fail "unknown option: $1" ;;
  esac

  bootstrap_init
  install_agents
  install_revdiff
  install_revdiff_integrations
  provision_harness
}

main "$@"

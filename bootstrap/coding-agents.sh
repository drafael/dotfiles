#!/bin/sh

set -eu

BOOTSTRAP_DIR=$(CDPATH= cd -- "$(dirname -- "$0")" && pwd)
# shellcheck source=lib.sh
. "$BOOTSTRAP_DIR/lib.sh"

usage() {
  printf '%s\n' \
    'Usage: coding-agents.sh' \
    '' \
    'Install missing coding-agent command-line tools.'
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

main() {
  case ${1:-} in
    -h|--help) usage; exit 0 ;;
    '') ;;
    *) fail "unknown option: $1" ;;
  esac

  bootstrap_init
  install_agents
}

main "$@"

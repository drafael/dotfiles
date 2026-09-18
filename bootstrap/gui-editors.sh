#!/bin/sh

set -eu

BOOTSTRAP_DIR=$(CDPATH= cd -- "$(dirname -- "$0")" && pwd)
# shellcheck source=lib.sh
. "$BOOTSTRAP_DIR/lib.sh"

usage() {
  printf '%s\n' \
    'Usage: gui-editors.sh' \
    '' \
    'Install optional GUI editors on macOS. Linux installations remain manual.'
}

main() {
  case ${1:-} in
    -h|--help) usage; exit 0 ;;
    '') ;;
    *) fail "unknown option: $1" ;;
  esac

  bootstrap_init
  if [ "$PLATFORM" != macos ]; then
    info 'GUI editor installation is not automated on Linux'
    printf '%s\n' \
      'Use the official distribution or desktop package UI for IntelliJ IDEA, VS Code, Cursor, and Zed.' \
      'On Omarchy, use Install > Editor.'
    exit 0
  fi

  info 'Ensuring optional GUI editors are installed'
  ensure_brew_casks intellij-idea visual-studio-code cursor zed
}

main "$@"

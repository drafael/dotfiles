#!/bin/sh

set -eu

BOOTSTRAP_DIR=$(CDPATH= cd -- "$(dirname -- "$0")" && pwd)
# shellcheck source=lib.sh
. "$BOOTSTRAP_DIR/lib.sh"

JAVASCRIPT_RUNTIME_MANAGER=""

usage() {
  printf '%s\n' \
    'Usage: bootstrap.sh [--javascript-runtime-manager=homebrew|mise]' \
    '' \
    'Provision the default command-line, JavaScript, Java, terminal, agent,' \
    'and dotfile environment. Optional GUI editors are installed separately' \
    'with gui-editors.sh.' \
    '' \
    'macOS uses Homebrew for current Node.js and Bun releases by default.' \
    'Pass mise to use mise instead. Linux platforms always use mise.'
}

parse_arguments() {
  while [ "$#" -gt 0 ]; do
    case $1 in
      --javascript-runtime-manager=*)
        JAVASCRIPT_RUNTIME_MANAGER=${1#*=}
        [ -n "$JAVASCRIPT_RUNTIME_MANAGER" ] || fail 'missing value for --javascript-runtime-manager'
        ;;
      --javascript-runtime-manager)
        [ "$#" -ge 2 ] || fail 'missing value for --javascript-runtime-manager'
        shift
        JAVASCRIPT_RUNTIME_MANAGER=$1
        ;;
      -h|--help)
        usage
        exit 0
        ;;
      *) fail "unknown option: $1" ;;
    esac
    shift
  done
}

validate_arguments() {
  case $JAVASCRIPT_RUNTIME_MANAGER in
    '') ;;
    homebrew)
      [ "$PLATFORM" = macos ] || fail 'Homebrew JavaScript runtimes are supported only on macOS'
      ;;
    mise) ;;
    *) fail "unsupported JavaScript runtime manager: $JAVASCRIPT_RUNTIME_MANAGER" ;;
  esac
}

run_category() {
  category_name=$1
  script_name=$2
  shift 2

  info "$category_name"
  if "$BOOTSTRAP_DIR/$script_name" "$@"; then
    return
  else
    status=$?
  fi
  fail "$script_name failed with status $status"
}

main() {
  parse_arguments "$@"
  bootstrap_init
  validate_arguments

  info "Bootstrapping $PLATFORM from $DOTFILES_DIR"
  run_category 'Command-line tools' cli-tools.sh

  if [ -n "$JAVASCRIPT_RUNTIME_MANAGER" ]; then
    run_category 'JavaScript and TypeScript' javascript.sh --runtime-manager "$JAVASCRIPT_RUNTIME_MANAGER"
  else
    run_category 'JavaScript and TypeScript' javascript.sh
  fi

  run_category 'Java development tools' java.sh
  run_category 'Terminal and editor tools' terminal-tools.sh
  run_category 'Coding agents' coding-agents.sh
  run_category 'Dotfile links' link-dotfiles.sh
  run_category 'Installation verification' verify.sh

  info 'Next steps'
  if [ "$PLATFORM" = omarchy ]; then
    printf '%s\n' '1. Open a new terminal.' '2. Run claude, codex, opencode, and pi once to install and authenticate them.'
  else
    printf '%s\n' '1. Run: exec zsh' '2. Run claude, codex, opencode, and pi to authenticate them.'
  fi
  printf '%s\n' '3. Add your Git identity to ~/.gitconfig.local.'
}

main "$@"

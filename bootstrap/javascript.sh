#!/bin/sh

set -eu

BOOTSTRAP_DIR=$(CDPATH= cd -- "$(dirname -- "$0")" && pwd)
# shellcheck source=lib.sh
. "$BOOTSTRAP_DIR/lib.sh"

JAVASCRIPT_RUNTIME_MANAGER=""

usage() {
  printf '%s\n' \
    'Usage: javascript.sh [--runtime-manager=homebrew|mise]' \
    '' \
    'macOS uses Homebrew for current Node.js and Bun releases by default.' \
    'Pass mise to use mise instead. Linux platforms always use mise.'
}

parse_arguments() {
  while [ "$#" -gt 0 ]; do
    case $1 in
      --runtime-manager=*)
        JAVASCRIPT_RUNTIME_MANAGER=${1#*=}
        [ -n "$JAVASCRIPT_RUNTIME_MANAGER" ] || fail 'missing value for --runtime-manager'
        ;;
      --runtime-manager)
        [ "$#" -ge 2 ] || fail 'missing value for --runtime-manager'
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

select_runtime_manager() {
  if [ -z "$JAVASCRIPT_RUNTIME_MANAGER" ]; then
    if [ "$PLATFORM" = macos ]; then
      JAVASCRIPT_RUNTIME_MANAGER=homebrew
    else
      JAVASCRIPT_RUNTIME_MANAGER=mise
    fi
  fi

  case $JAVASCRIPT_RUNTIME_MANAGER in
    homebrew)
      [ "$PLATFORM" = macos ] || fail 'Homebrew JavaScript runtimes are supported only on macOS'
      ;;
    mise) ;;
    *) fail "unsupported JavaScript runtime manager: $JAVASCRIPT_RUNTIME_MANAGER" ;;
  esac
}

ensure_mise_runtime() {
  runtime_name=$1
  runtime_version=$2
  if mise which "$runtime_name" >/dev/null 2>&1; then
    return
  fi
  mise use --global "$runtime_name@$runtime_version"
}

ensure_npm_tool() {
  command_name=$1
  package_name=$2
  if npm list --global --depth=0 "$package_name" >/dev/null 2>&1; then
    return
  fi
  npm install --global "$package_name@latest"
  require_command "$command_name"
}

install_javascript_tooling() {
  case $JAVASCRIPT_RUNTIME_MANAGER in
    homebrew)
      info 'Ensuring Homebrew Node.js and Bun are installed'
      ensure_brew_formulas node bun
      refresh_standard_paths
      ;;
    mise)
      case $PLATFORM in
        macos) ensure_brew_formulas mise ;;
        ubuntu) install_mise ;;
        arch) ensure_arch_packages mise ;;
        omarchy) ensure_omarchy_packages mise-bin ;;
      esac
      refresh_standard_paths
      require_command mise
      info 'Ensuring Node.js and Bun runtimes are installed with mise'
      ensure_mise_runtime node lts
      ensure_mise_runtime bun latest
      mise reshim
      refresh_standard_paths
      ;;
  esac

  require_command node
  require_command npm
  require_command bun

  info 'Ensuring TypeScript tools are installed'
  ensure_npm_tool tsc typescript
  ensure_npm_tool typescript-language-server typescript-language-server
  ensure_npm_tool tsx tsx
  reshim_mise_if_available
}

main() {
  parse_arguments "$@"
  bootstrap_init
  select_runtime_manager
  install_javascript_tooling
}

main "$@"

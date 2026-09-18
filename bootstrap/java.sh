#!/bin/sh

set -eu

BOOTSTRAP_DIR=$(CDPATH= cd -- "$(dirname -- "$0")" && pwd)
# shellcheck source=lib.sh
. "$BOOTSTRAP_DIR/lib.sh"

usage() {
  printf '%s\n' \
    'Usage: java.sh' \
    '' \
    'Install missing JDK 25 and Java build tools without upgrading them.'
}

install_java_tools() {
  info "Ensuring Java development tools are installed on $PLATFORM"
  case $PLATFORM in
    macos)
      ensure_brew_formulas openjdk@25 maven gradle
      jdk_source="$(brew --prefix openjdk@25)/libexec/openjdk.jdk"
      jdk_destination=/Library/Java/JavaVirtualMachines/openjdk-25.jdk
      if [ -L "$jdk_destination" ] && [ "$(readlink "$jdk_destination")" = "$jdk_source" ]; then
        :
      elif [ -e "$jdk_destination" ] || [ -L "$jdk_destination" ]; then
        fail "$jdk_destination already exists and does not point to $jdk_source; back it up or remove it, then rerun bootstrap"
      else
        sudo mkdir -p /Library/Java/JavaVirtualMachines
        sudo ln -s "$jdk_source" "$jdk_destination"
      fi
      ;;
    ubuntu)
      ensure_ubuntu_packages openjdk-25-jdk maven
      ;;
    arch)
      ensure_arch_packages jdk25-openjdk maven gradle
      ;;
    omarchy)
      ensure_omarchy_packages jdk25-openjdk maven gradle
      ;;
  esac
}

main() {
  case ${1:-} in
    -h|--help) usage; exit 0 ;;
    '') ;;
    *) fail "unknown option: $1" ;;
  esac

  bootstrap_init
  install_java_tools
  set_java_environment
  require_command java
  require_command javac
  require_command mvn
  if [ "$PLATFORM" != ubuntu ]; then
    require_command gradle
  fi
}

main "$@"

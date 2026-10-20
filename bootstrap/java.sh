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
      ensure_bootstrap_packages brew-formula java
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
      ensure_bootstrap_packages system java
      ;;
    fedora)
      ensure_bootstrap_packages system java
      ;;
    arch)
      ensure_bootstrap_packages system java
      ;;
    omarchy)
      ensure_bootstrap_packages system java
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
  if [ "$PLATFORM" != ubuntu ] && [ "$PLATFORM" != fedora ]; then
    require_command gradle
  fi
}

main "$@"

#!/bin/sh

# Shared bootstrap primitives. Executable category scripts set BOOTSTRAP_DIR
# before sourcing this file.

DOTFILES_DIR=$(CDPATH= cd -- "$BOOTSTRAP_DIR/.." && pwd)
EXPECTED_DOTFILES_DIR="$HOME/.dotfiles"
BACKUP_BASE="$HOME/.dotfiles-backups"
BACKUP_DIR=""
PLATFORM=""
XDG_CONFIG_HOME=${XDG_CONFIG_HOME:-"$HOME/.config"}

# Keep user-installed tools and platform package locations visible when a
# category script is run directly from a fresh shell.
PATH="$HOME/.local/bin:$HOME/.opencode/bin:$HOME/.local/share/pi-node/current/bin:$HOME/.local/share/mise/shims:/snap/bin:$PATH"
export PATH XDG_CONFIG_HOME

info() {
  printf '\n==> %s\n' "$*"
}

warn() {
  printf 'warning: %s\n' "$*" >&2
}

fail() {
  printf 'error: %s\n' "$*" >&2
  exit 1
}

require_command() {
  command -v "$1" >/dev/null 2>&1 || fail "required command not found: $1"
}

detect_platform() {
  case $(uname -s) in
    Darwin)
      PLATFORM=macos
      ;;
    Linux)
      [ -r /etc/os-release ] || fail '/etc/os-release is missing'
      # shellcheck disable=SC1091
      . /etc/os-release
      if command -v omarchy >/dev/null 2>&1 || [ "${ID:-}" = omarchy ]; then
        PLATFORM=omarchy
      elif [ "${ID:-}" = ubuntu ]; then
        major_version=${VERSION_ID%%.*}
        [ "$major_version" -ge 24 ] 2>/dev/null || fail 'Ubuntu 24.04 or newer is required'
        PLATFORM=ubuntu
      elif [ "${ID:-}" = arch ]; then
        PLATFORM=arch
      else
        fail "unsupported Linux distribution: ${PRETTY_NAME:-${ID:-unknown}}"
      fi
      ;;
    *)
      fail "unsupported operating system: $(uname -s)"
      ;;
  esac
}

refresh_standard_paths() {
  if [ -x /opt/homebrew/bin/brew ]; then
    PATH="/opt/homebrew/bin:/opt/homebrew/sbin:$PATH"
  elif [ -x /usr/local/bin/brew ]; then
    PATH="/usr/local/bin:/usr/local/sbin:$PATH"
  fi
  PATH="$HOME/.local/bin:$HOME/.opencode/bin:$HOME/.local/share/pi-node/current/bin:$HOME/.local/share/mise/shims:/snap/bin:$PATH"
  export PATH
  hash -r 2>/dev/null || true
}

bootstrap_init() {
  [ "$(id -u)" -ne 0 ] || fail 'run this script as your normal user, not root'
  [ "$DOTFILES_DIR" = "$EXPECTED_DOTFILES_DIR" ] || fail "clone this repository to $EXPECTED_DOTFILES_DIR before running bootstrap"
  detect_platform
  refresh_standard_paths
}

download_installer() {
  label=$1
  shell_command=$2
  url=$3
  shift 3

  require_command curl
  installer=$(mktemp "${TMPDIR:-/tmp}/dotfiles-installer.XXXXXX")
  info "Installing $label"
  if ! curl -fsSL "$url" -o "$installer"; then
    rm -f "$installer"
    fail "failed to download the $label installer"
  fi
  if "$shell_command" "$installer" "$@"; then
    :
  else
    status=$?
    rm -f "$installer"
    fail "$label installer failed with status $status"
  fi
  rm -f "$installer"
}

install_github_release_archive() {
  label=$1
  repository=$2
  archive_prefix=$3
  archive_suffix=$4
  binary_name=$5

  temp_dir=$(mktemp -d "${TMPDIR:-/tmp}/dotfiles-release.XXXXXX")
  metadata="$temp_dir/release.json"
  curl -fsSL "https://api.github.com/repos/$repository/releases/latest" -o "$metadata"

  release_tag=$(jq -er '.tag_name' "$metadata") || fail "could not determine the latest $label release"
  release_version=${release_tag#v}
  archive="${archive_prefix}${release_version}${archive_suffix}"
  archive_url=$(jq -er --arg name "$archive" '.assets[] | select(.name == $name) | .browser_download_url' "$metadata") ||
    fail "$label release asset not found: $archive"
  checksums_url=$(jq -er '(([.assets[] | select(.name == "checksums.txt")][0] // [.assets[] | select(.name | endswith("_checksums.txt"))][0]).browser_download_url // empty)' "$metadata") ||
    fail "$label release checksums were not published"

  info "Installing $label $release_tag"
  curl -fsSL "$archive_url" -o "$temp_dir/$archive"
  curl -fsSL "$checksums_url" -o "$temp_dir/checksums.txt"
  checksum_line=$(awk -v name="$archive" '$2 == name { print; exit }' "$temp_dir/checksums.txt")
  [ -n "$checksum_line" ] || fail "$label checksum not found for $archive"
  printf '%s\n' "$checksum_line" >"$temp_dir/checksum"
  (cd "$temp_dir" && sha256sum -c checksum)

  mkdir -p "$temp_dir/extracted" "$HOME/.local/bin"
  tar -xzf "$temp_dir/$archive" -C "$temp_dir/extracted"
  binary_source=$(find "$temp_dir/extracted" -type f -name "$binary_name" -print | head -1)
  [ -n "$binary_source" ] || fail "$binary_name was not found in $archive"
  install -m 0755 "$binary_source" "$HOME/.local/bin/$binary_name"
  rm -rf "$temp_dir"
  refresh_standard_paths
  require_command "$binary_name"
}

ensure_homebrew() {
  refresh_standard_paths
  if command -v brew >/dev/null 2>&1; then
    return
  fi

  require_command curl
  download_installer Homebrew /bin/bash https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh
  refresh_standard_paths
  require_command brew
}

ensure_brew_formulas() {
  ensure_homebrew
  missing_packages=""
  for package_name in "$@"; do
    if ! brew list --formula "$package_name" >/dev/null 2>&1; then
      missing_packages="$missing_packages $package_name"
    fi
  done
  if [ -n "$missing_packages" ]; then
    # Package names are fixed by these bootstrap scripts.
    # shellcheck disable=SC2086
    brew install $missing_packages
  fi
}

ensure_brew_casks() {
  ensure_homebrew
  missing_packages=""
  for package_name in "$@"; do
    if ! brew list --cask "$package_name" >/dev/null 2>&1; then
      missing_packages="$missing_packages $package_name"
    fi
  done
  if [ -n "$missing_packages" ]; then
    # Package names are fixed by these bootstrap scripts.
    # shellcheck disable=SC2086
    brew install --cask $missing_packages
  fi
}

ensure_ubuntu_packages() {
  missing_packages=""
  for package_name in "$@"; do
    if ! dpkg-query -W -f='${Status}' "$package_name" 2>/dev/null | grep -q 'install ok installed'; then
      missing_packages="$missing_packages $package_name"
    fi
  done
  if [ -n "$missing_packages" ]; then
    sudo apt-get update
    # Package names are fixed by these bootstrap scripts.
    # shellcheck disable=SC2086
    sudo apt-get install -y $missing_packages
  fi
}

ensure_arch_packages() {
  missing_packages=""
  for package_name in "$@"; do
    if ! pacman -Q "$package_name" >/dev/null 2>&1; then
      missing_packages="$missing_packages $package_name"
    fi
  done
  if [ -n "$missing_packages" ]; then
    # Package names are fixed by these bootstrap scripts.
    # shellcheck disable=SC2086
    sudo pacman -S --needed --noconfirm $missing_packages
  fi
}

ensure_omarchy_packages() {
  # omarchy pkg add is the supported idempotent package entry point and keeps
  # Omarchy's package lifecycle intact.
  omarchy pkg add "$@"
}

ensure_curl() {
  if command -v curl >/dev/null 2>&1; then
    return
  fi

  case $PLATFORM in
    macos) fail 'curl is required but is not available' ;;
    ubuntu) ensure_ubuntu_packages curl ca-certificates ;;
    arch) ensure_arch_packages curl ca-certificates ;;
    omarchy) ensure_omarchy_packages curl ca-certificates ;;
  esac
  require_command curl
}

install_mise() {
  if command -v mise >/dev/null 2>&1; then
    return
  fi
  ensure_curl
  download_installer mise sh https://mise.run
  refresh_standard_paths
  require_command mise
}

reshim_mise_if_available() {
  if command -v mise >/dev/null 2>&1; then
    mise reshim
  fi
}

create_backup_dir() {
  if [ -n "$BACKUP_DIR" ]; then
    return
  fi

  timestamp=$(date '+%Y%m%d-%H%M%S')
  BACKUP_DIR="$BACKUP_BASE/$timestamp"
  suffix=0
  while [ -e "$BACKUP_DIR" ]; do
    suffix=$((suffix + 1))
    BACKUP_DIR="$BACKUP_BASE/$timestamp-$suffix"
  done
  mkdir -p "$BACKUP_DIR"
}

backup_path() {
  backup_source=$1
  backup_relative=${backup_source#"$HOME"/}
  create_backup_dir
  backup_destination="$BACKUP_DIR/$backup_relative"
  mkdir -p "$(dirname -- "$backup_destination")"
  mv "$backup_source" "$backup_destination"
  printf 'backed up %s -> %s\n' "$backup_source" "$backup_destination"
}

backup_copy() {
  copy_source=$1
  copy_relative=${copy_source#"$HOME"/}
  create_backup_dir
  copy_destination="$BACKUP_DIR/$copy_relative"
  mkdir -p "$(dirname -- "$copy_destination")"
  cp -p "$copy_source" "$copy_destination"
  printf 'backed up %s -> %s\n' "$copy_source" "$copy_destination"
}

link_path() {
  link_source=$1
  link_destination=$2

  if [ -L "$link_destination" ] && [ "$(readlink "$link_destination")" = "$link_source" ]; then
    printf 'linked     %s\n' "$link_destination"
    return
  fi

  if [ -e "$link_destination" ] || [ -L "$link_destination" ]; then
    backup_path "$link_destination"
  fi

  mkdir -p "$(dirname -- "$link_destination")"
  ln -s "$link_source" "$link_destination"
  printf 'linked     %s -> %s\n' "$link_destination" "$link_source"
}

resolved_existing_path() {
  resolve_input=$1
  if [ -d "$resolve_input" ]; then
    (CDPATH= cd -- "$resolve_input" && pwd -P)
    return
  fi
  [ -e "$resolve_input" ] || return 1
  resolve_parent=$(CDPATH= cd -- "$(dirname -- "$resolve_input")" && pwd -P) || return 1
  printf '%s/%s\n' "$resolve_parent" "$(basename -- "$resolve_input")"
}

symlink_points_to_path() {
  checked_link=$1
  expected_path=$2
  [ -L "$checked_link" ] || return 1

  raw_target=$(readlink "$checked_link")
  case $raw_target in
    /*) candidate_path=$raw_target ;;
    *) candidate_path="$(dirname -- "$checked_link")/$raw_target" ;;
  esac

  resolved_candidate=$(resolved_existing_path "$candidate_path") || return 1
  resolved_expected=$(resolved_existing_path "$expected_path") || return 1
  [ "$resolved_candidate" = "$resolved_expected" ]
}

link_path_resolved() {
  resolved_link_source=$1
  resolved_link_destination=$2
  if symlink_points_to_path "$resolved_link_destination" "$resolved_link_source"; then
    printf 'linked     %s\n' "$resolved_link_destination"
    return
  fi
  link_path "$resolved_link_source" "$resolved_link_destination"
}

ensure_real_directory() {
  directory_path=$1
  if [ -d "$directory_path" ] && [ ! -L "$directory_path" ]; then
    return
  fi
  if [ -e "$directory_path" ] || [ -L "$directory_path" ]; then
    backup_path "$directory_path"
  fi
  mkdir -p "$directory_path"
}

set_java_environment() {
  JAVA_HOME=""
  case $PLATFORM in
    macos)
      if [ -x /usr/libexec/java_home ] && /usr/libexec/java_home -v 25 >/dev/null 2>&1; then
        JAVA_HOME=$(/usr/libexec/java_home -v 25)
      fi
      ;;
    ubuntu)
      for candidate in /usr/lib/jvm/java-25-openjdk-*; do
        if [ -x "$candidate/bin/java" ]; then
          JAVA_HOME=$candidate
          break
        fi
      done
      ;;
    arch|omarchy)
      JAVA_HOME=/usr/lib/jvm/java-25-openjdk
      ;;
  esac

  if [ -n "$JAVA_HOME" ] && [ -x "$JAVA_HOME/bin/java" ]; then
    PATH="$JAVA_HOME/bin:$PATH"
    export JAVA_HOME PATH
  fi
}

first_line() {
  "$@" 2>&1 | awk 'NF { print; exit }'
}

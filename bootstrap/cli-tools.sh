#!/bin/sh

set -eu

BOOTSTRAP_DIR=$(CDPATH= cd -- "$(dirname -- "$0")" && pwd)
# shellcheck source=lib.sh
. "$BOOTSTRAP_DIR/lib.sh"

usage() {
  printf '%s\n' \
    'Usage: cli-tools.sh' \
    '' \
    'Install missing command-line tools without upgrading installed tools.'
}

install_starship() {
  if command -v starship >/dev/null 2>&1; then
    return
  fi
  mkdir -p "$HOME/.local/bin"
  download_installer Starship sh https://starship.rs/install.sh -y -b "$HOME/.local/bin"
}

install_ubuntu_glab() {
  info 'Ensuring GitLab CLI is installed'
  sudo systemctl enable --now snapd.socket >/dev/null 2>&1 || warn 'could not start snapd.socket; snap may already be active'
  if ! sudo snap list glab >/dev/null 2>&1; then
    sudo snap install glab
  fi
  sudo snap connect glab:ssh-keys >/dev/null 2>&1 || warn 'could not grant glab access to SSH keys'
  sudo snap connect glab:password-manager-service >/dev/null 2>&1 || warn 'could not connect glab to the desktop keyring; it may use plaintext credential storage'
}

install_ubuntu_yazi() {
  if command -v yazi >/dev/null 2>&1; then
    return
  fi

  info 'Configuring the official Yazi APT repository'
  keyring=/usr/share/keyrings/yazi-keyring.gpg
  source_list=/etc/apt/sources.list.d/yazi.list
  source_entry='deb [signed-by=/usr/share/keyrings/yazi-keyring.gpg] https://yazi-rs.github.io/builds/ stable main'

  if [ ! -s "$keyring" ]; then
    curl -fsSL https://yazi-rs.github.io/builds/yazi-keyring.gpg | sudo tee "$keyring" >/dev/null
  fi
  if ! grep -Fqx "$source_entry" "$source_list" 2>/dev/null; then
    printf '%s\n' "$source_entry" | sudo tee "$source_list" >/dev/null
  fi
  ensure_ubuntu_packages yazi
  require_command yazi
}

install_optional_ubuntu_resvg() {
  if command -v resvg >/dev/null 2>&1; then
    return
  fi
  if apt-cache show resvg >/dev/null 2>&1; then
    ensure_ubuntu_packages resvg
  else
    warn 'resvg is unavailable from the configured Ubuntu repositories; Yazi SVG previews will be unavailable'
  fi
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
  checksums_url=$(jq -er '.assets[] | select(.name == "checksums.txt") | .browser_download_url' "$metadata") ||
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

install_linux_lazygit() {
  if command -v lazygit >/dev/null 2>&1; then
    return
  fi

  case $(uname -m) in
    x86_64|amd64) release_arch=x86_64 ;;
    aarch64|arm64) release_arch=arm64 ;;
    *) fail "LazyGit does not publish a supported Linux archive for $(uname -m)" ;;
  esac
  install_github_release_archive LazyGit jesseduffield/lazygit lazygit_ "_linux_${release_arch}.tar.gz" lazygit
}

install_linux_mdc() {
  if command -v mdc >/dev/null 2>&1; then
    return
  fi

  case $(uname -m) in
    x86_64|amd64) release_arch=amd64 ;;
    aarch64|arm64) release_arch=arm64 ;;
    *) fail "Midday Commander does not publish a supported Linux archive for $(uname -m)" ;;
  esac
  install_github_release_archive 'Midday Commander' kooler/MiddayCommander MiddayCommander_ "_linux_${release_arch}.tar.gz" mdc
}

install_macos_cli_tools() {
  ensure_brew_formulas \
    git git-lfs gh glab starship tmux fzf fd zoxide ripgrep \
    btop htop lazygit tig midnight-commander yazi kooler/apps/middaycommander \
    jq tree wget sevenzip poppler resvg

  if ! command -v ffmpeg >/dev/null 2>&1; then
    ensure_brew_formulas ffmpeg-full
    refresh_standard_paths
    command -v ffmpeg >/dev/null 2>&1 || brew link --force --overwrite ffmpeg-full
  fi
  if ! command -v magick >/dev/null 2>&1 && ! command -v convert >/dev/null 2>&1; then
    ensure_brew_formulas imagemagick-full
    refresh_standard_paths
    command -v magick >/dev/null 2>&1 || brew link --force --overwrite imagemagick-full
  fi
}

install_ubuntu_cli_tools() {
  ensure_ubuntu_packages software-properties-common curl ca-certificates xz-utils python3 snapd
  sudo add-apt-repository -y universe
  ensure_ubuntu_packages \
    git git-lfs gh zsh tmux fzf fd-find zoxide ripgrep wl-clipboard build-essential unzip \
    btop htop tig mc jq tree wget file ffmpeg 7zip poppler-utils imagemagick

  install_ubuntu_glab
  install_starship
  install_ubuntu_yazi
  install_optional_ubuntu_resvg
  install_linux_lazygit
  install_linux_mdc
  link_path /usr/bin/fdfind "$HOME/.local/bin/fd"
}

install_arch_cli_tools() {
  ensure_arch_packages \
    git git-lfs github-cli glab curl zsh starship tmux fzf fd zoxide ripgrep wl-clipboard base-devel unzip \
    btop htop lazygit tig mc yazi jq tree wget file ffmpeg 7zip poppler resvg imagemagick
  install_linux_mdc
}

install_omarchy_cli_tools() {
  ensure_omarchy_packages \
    git git-lfs glab tmux fzf fd zoxide ripgrep starship wl-clipboard base-devel unzip \
    btop htop lazygit tig mc yazi jq tree wget file ffmpeg 7zip poppler resvg imagemagick
  command -v gh >/dev/null 2>&1 || omarchy-mise-install gh
  install_linux_mdc
}

verify_cli_commands() {
  for command_name in git git-lfs gh glab starship tmux fzf fd zoxide rg btop htop lazygit tig mc yazi mdc jq tree wget; do
    require_command "$command_name"
  done
  require_command file
  require_command ffmpeg
  if ! command -v 7zz >/dev/null 2>&1 && ! command -v 7z >/dev/null 2>&1; then
    fail 'required command not found: 7zz or 7z'
  fi
  require_command pdftotext
  if ! command -v magick >/dev/null 2>&1 && ! command -v convert >/dev/null 2>&1; then
    fail 'required command not found: magick or convert'
  fi
}

install_cli_tools() {
  info "Ensuring command-line tools are installed on $PLATFORM"
  case $PLATFORM in
    macos) install_macos_cli_tools ;;
    ubuntu) install_ubuntu_cli_tools ;;
    arch) install_arch_cli_tools ;;
    omarchy) install_omarchy_cli_tools ;;
  esac
  refresh_standard_paths
  verify_cli_commands
}

main() {
  case ${1:-} in
    -h|--help) usage; exit 0 ;;
    '') ;;
    *) fail "unknown option: $1" ;;
  esac

  bootstrap_init
  install_cli_tools
}

main "$@"

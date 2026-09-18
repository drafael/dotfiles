#!/bin/sh

set -eu

BOOTSTRAP_DIR=$(CDPATH= cd -- "$(dirname -- "$0")" && pwd)
# shellcheck source=lib.sh
. "$BOOTSTRAP_DIR/lib.sh"

usage() {
  printf '%s\n' \
    'Usage: terminal-tools.sh' \
    '' \
    'Install missing Neovim and the platform terminal application.'
}

nvim_version_is_supported() {
  command -v nvim >/dev/null 2>&1 || return 1
  version=$(nvim --version | awk 'NR == 1 { sub(/^v/, "", $2); split($2, part, "."); print part[1] "." part[2] }')
  major=${version%%.*}
  minor=${version#*.}
  case "$major:$minor" in
    *[!0-9:]*|:*) return 1 ;;
  esac
  [ "$major" -gt 0 ] || [ "$minor" -ge 11 ]
}

install_ubuntu_neovim() {
  if nvim_version_is_supported; then
    return
  fi

  case $(uname -m) in
    x86_64|amd64) archive=nvim-linux-x86_64.tar.gz ;;
    aarch64|arm64) archive=nvim-linux-arm64.tar.gz ;;
    *) fail "Neovim does not publish a supported Linux archive for $(uname -m)" ;;
  esac

  info 'Installing current Neovim for Ubuntu'
  temp_dir=$(mktemp -d "${TMPDIR:-/tmp}/dotfiles-neovim.XXXXXX")
  metadata="$temp_dir/release.json"
  curl -fsSL https://api.github.com/repos/neovim/neovim/releases/latest -o "$metadata"
  asset_data=$(python3 - "$archive" "$metadata" <<'PY'
import json
import sys

name = sys.argv[1]
with open(sys.argv[2], encoding="utf-8") as release_file:
    assets = json.load(release_file)["assets"]
for asset in assets:
    if asset["name"] == name:
        digest = asset.get("digest", "")
        if not digest.startswith("sha256:"):
            raise SystemExit(f"release asset {name} has no SHA-256 digest")
        print(asset["browser_download_url"])
        print(digest.removeprefix("sha256:"))
        break
else:
    raise SystemExit(f"release asset not found: {name}")
PY
)
  download_url=$(printf '%s\n' "$asset_data" | sed -n '1p')
  expected_digest=$(printf '%s\n' "$asset_data" | sed -n '2p')
  curl -fsSL "$download_url" -o "$temp_dir/$archive"
  printf '%s  %s\n' "$expected_digest" "$archive" >"$temp_dir/checksum"
  (cd "$temp_dir" && sha256sum -c checksum)
  tar -xzf "$temp_dir/$archive" -C "$temp_dir"

  install_root="$HOME/.local/share/dotfiles"
  extracted_dir=${archive%.tar.gz}
  rm -rf "$install_root/nvim"
  mkdir -p "$install_root"
  mv "$temp_dir/$extracted_dir" "$install_root/nvim"
  rm -rf "$temp_dir"
  link_path "$install_root/nvim/bin/nvim" "$HOME/.local/bin/nvim"
}

install_terminal_tools() {
  info "Ensuring terminal tools are installed on $PLATFORM"
  case $PLATFORM in
    macos)
      ensure_brew_formulas neovim
      ensure_brew_casks ghostty
      ;;
    ubuntu)
      ensure_ubuntu_packages curl ca-certificates xz-utils python3 kitty
      install_ubuntu_neovim
      ;;
    arch)
      ensure_arch_packages neovim ghostty
      ;;
    omarchy)
      ensure_omarchy_packages nvim
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
  install_terminal_tools
  refresh_standard_paths
  require_command nvim
}

main "$@"

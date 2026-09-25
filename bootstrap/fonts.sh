#!/bin/sh

set -eu

BOOTSTRAP_DIR=$(CDPATH= cd -- "$(dirname -- "$0")" && pwd)
# shellcheck source=lib.sh
. "$BOOTSTRAP_DIR/lib.sh"

NERD_FONTS_REPOSITORY=ryanoasis/nerd-fonts

usage() {
  printf '%s\n' \
    'Usage: fonts.sh' \
    '' \
    'Install Fira Code, FiraCode Nerd Font, and symbols-only Nerd Fonts.' \
    'Font installation does not change the selected terminal or desktop font.'
}

font_family_is_available() {
  family_name=$1
  fc-list : family 2>/dev/null | grep -Fq "$family_name"
}

install_ubuntu_nerd_font_asset() {
  metadata=$1
  temp_dir=$2
  asset_name=$3
  destination=$4

  asset_url=$(jq -er --arg name "$asset_name" '.assets[] | select(.name == $name) | .browser_download_url' "$metadata") ||
    fail "Nerd Fonts release asset not found: $asset_name"
  asset_digest=$(jq -er --arg name "$asset_name" '.assets[] | select(.name == $name) | .digest // empty' "$metadata") ||
    fail "Nerd Fonts release asset has no digest: $asset_name"
  case $asset_digest in
    sha256:*) expected_digest=${asset_digest#sha256:} ;;
    *) fail "Nerd Fonts release asset has no SHA-256 digest: $asset_name" ;;
  esac

  archive="$temp_dir/$asset_name"
  extracted="$temp_dir/${asset_name%.tar.xz}"
  curl -fsSL "$asset_url" -o "$archive"
  printf '%s  %s\n' "$expected_digest" "$asset_name" >"$temp_dir/checksum"
  (cd "$temp_dir" && sha256sum -c checksum)

  mkdir -p "$extracted"
  tar -xJf "$archive" -C "$extracted"
  if ! find "$extracted" -type f \( -name '*.ttf' -o -name '*.otf' \) -print | grep -q .; then
    fail "no font files found in $asset_name"
  fi

  rm -rf "$destination"
  mkdir -p "$destination"
  find "$extracted" -type f \( -name '*.ttf' -o -name '*.otf' \) -exec cp -f {} "$destination/" \;
}

install_ubuntu_fonts() {
  ensure_ubuntu_packages software-properties-common
  sudo add-apt-repository -y universe
  ensure_ubuntu_packages ca-certificates curl fontconfig fonts-firacode jq xz-utils

  install_firacode_nerd=false
  install_symbols_nerd=false
  symbols_fallback_config="$XDG_CONFIG_HOME/fontconfig/conf.d/10-nerd-font-symbols.conf"
  font_family_is_available 'FiraCode Nerd Font Mono' || install_firacode_nerd=true
  if ! font_family_is_available 'Symbols Nerd Font Mono' || [ ! -f "$symbols_fallback_config" ]; then
    install_symbols_nerd=true
  fi
  if [ "$install_firacode_nerd" = false ] && [ "$install_symbols_nerd" = false ]; then
    return
  fi

  temp_dir=$(mktemp -d "${TMPDIR:-/tmp}/dotfiles-fonts.XXXXXX")
  metadata="$temp_dir/release.json"
  curl -fsSL "https://api.github.com/repos/$NERD_FONTS_REPOSITORY/releases/latest" -o "$metadata"
  release_tag=$(jq -er '.tag_name' "$metadata") || fail 'could not determine the latest Nerd Fonts release'
  font_root=${XDG_DATA_HOME:-"$HOME/.local/share"}/fonts
  info "Installing Nerd Fonts $release_tag"

  if [ "$install_firacode_nerd" = true ]; then
    install_ubuntu_nerd_font_asset "$metadata" "$temp_dir" FiraCode.tar.xz "$font_root/FiraCodeNerdFont"
  fi
  if [ "$install_symbols_nerd" = true ]; then
    symbols_extract_dir="$temp_dir/NerdFontsSymbolsOnly"
    install_ubuntu_nerd_font_asset "$metadata" "$temp_dir" NerdFontsSymbolsOnly.tar.xz "$font_root/NerdFontsSymbolsOnly"
    fallback_config=$(find "$symbols_extract_dir" -type f -name 10-nerd-font-symbols.conf -print | head -1)
    [ -n "$fallback_config" ] || fail 'Nerd Fonts symbols fallback configuration was not found'
    mkdir -p "$(dirname -- "$symbols_fallback_config")"
    cp -f "$fallback_config" "$symbols_fallback_config"
  fi

  rm -rf "$temp_dir"
  fc-cache -f
  font_family_is_available 'FiraCode Nerd Font Mono' || fail 'FiraCode Nerd Font Mono was not installed'
  font_family_is_available 'Symbols Nerd Font Mono' || fail 'Symbols Nerd Font Mono was not installed'
  [ -f "$symbols_fallback_config" ] || fail 'Nerd Fonts symbols fallback configuration was not installed'
}

install_fonts() {
  info "Ensuring workstation fonts are installed on $PLATFORM"
  case $PLATFORM in
    macos)
      # Yazi uses Nerd Font icons. The symbols-only family can be selected as a
      # terminal fallback without replacing the primary text font.
      ensure_brew_casks \
        font-fira-code \
        font-fira-code-nerd-font \
        font-symbols-only-nerd-font
      ;;
    ubuntu)
      install_ubuntu_fonts
      ;;
    arch)
      ensure_arch_packages \
        ttf-fira-code \
        ttf-firacode-nerd \
        ttf-nerd-fonts-symbols \
        ttf-nerd-fonts-symbols-mono
      ;;
    omarchy)
      # Keep Omarchy's selected system font and install the families only.
      ensure_omarchy_packages \
        ttf-fira-code \
        ttf-firacode-nerd \
        ttf-nerd-fonts-symbols \
        ttf-nerd-fonts-symbols-mono
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
  install_fonts
}

main "$@"

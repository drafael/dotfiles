#!/bin/sh

set -eu

BOOTSTRAP_DIR=$(CDPATH= cd -- "$(dirname -- "$0")" && pwd)
# shellcheck source=lib.sh
. "$BOOTSTRAP_DIR/lib.sh"

NERD_FONTS_REPOSITORY=ryanoasis/nerd-fonts
# Ubuntu 24.04 has no Source Code Pro package, so pin Adobe's upstream OTF release.
SOURCE_CODE_PRO_VERSION=2.042R-u_1.062R-i
SOURCE_CODE_PRO_ARCHIVE="OTF-source-code-pro-$SOURCE_CODE_PRO_VERSION.zip"
SOURCE_CODE_PRO_SHA256=754a2e3ebb945ae905d720ac5896b3b34acc9546dd6551ef9536869788629dae
SOURCE_CODE_PRO_URL="https://github.com/adobe-fonts/source-code-pro/releases/download/2.042R-u/1.062R-i/1.026R-vf/$SOURCE_CODE_PRO_ARCHIVE"

usage() {
  printf '%s\n' \
    'Usage: fonts.sh' \
    '' \
    'Install Fira Code, JetBrains Mono, Cascadia Code, Source Code Pro, Hack,' \
    'FiraCode Nerd Font, and symbols-only Nerd Fonts.' \
    'Font installation does not change the selected terminal or desktop font.'
}

font_family_is_available() {
  family_name=$1
  fc-list : family 2>/dev/null | grep -Fq "$family_name"
}

install_nerd_font_fallback_config() {
  fallback_source=$1
  fallback_destination="$XDG_CONFIG_HOME/fontconfig/conf.d/10-nerd-font-symbols.conf"
  fallback_temp=$(mktemp "${TMPDIR:-/tmp}/dotfiles-nerd-font-fallback.XXXXXX")
  sed 's#<family>Symbols Nerd Font</family>#<family>Symbols Nerd Font Mono</family>#g' \
    "$fallback_source" >"$fallback_temp"
  grep -Fq '<family>Symbols Nerd Font Mono</family>' "$fallback_temp" || {
    rm -f "$fallback_temp"
    fail 'Nerd Fonts fallback configuration does not define the monospace symbols family'
  }
  mkdir -p "$(dirname -- "$fallback_destination")"
  if ! cmp -s "$fallback_temp" "$fallback_destination"; then
    cp -f "$fallback_temp" "$fallback_destination"
  fi
  rm -f "$fallback_temp"
}

install_packaged_nerd_font_fallback_config() {
  fallback_source=/usr/share/fontconfig/conf.avail/10-nerd-font-symbols.conf
  [ -f "$fallback_source" ] || fail "Nerd Fonts fallback configuration not found: $fallback_source"
  install_nerd_font_fallback_config "$fallback_source"
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

install_ubuntu_source_code_pro() {
  font_family_is_available 'Source Code Pro' && return

  info "Installing Source Code Pro $SOURCE_CODE_PRO_VERSION"
  temp_dir=$(mktemp -d "${TMPDIR:-/tmp}/dotfiles-source-code-pro.XXXXXX")
  curl -fsSL "$SOURCE_CODE_PRO_URL" -o "$temp_dir/$SOURCE_CODE_PRO_ARCHIVE"
  printf '%s  %s\n' "$SOURCE_CODE_PRO_SHA256" "$SOURCE_CODE_PRO_ARCHIVE" >"$temp_dir/checksum"
  (cd "$temp_dir" && sha256sum -c checksum)
  unzip -q "$temp_dir/$SOURCE_CODE_PRO_ARCHIVE" -d "$temp_dir/extracted"

  source_dir="$temp_dir/extracted/OTF"
  if ! find "$source_dir" -type f -name '*.otf' -print | grep -q .; then
    fail "no OpenType fonts found in $SOURCE_CODE_PRO_ARCHIVE"
  fi

  destination=${XDG_DATA_HOME:-"$HOME/.local/share"}/fonts/SourceCodePro
  rm -rf "$destination"
  mkdir -p "$destination"
  find "$source_dir" -type f -name '*.otf' -exec cp -f {} "$destination/" \;
  rm -rf "$temp_dir"
  fc-cache -f
  font_family_is_available 'Source Code Pro' || fail 'Source Code Pro was not installed'
}

install_ubuntu_fonts() {
  ensure_ubuntu_packages software-properties-common
  sudo add-apt-repository -y universe
  ensure_ubuntu_packages \
    ca-certificates \
    curl \
    fontconfig \
    fonts-cascadia-code \
    fonts-firacode \
    fonts-hack \
    fonts-jetbrains-mono \
    jq \
    unzip \
    xz-utils
  install_ubuntu_source_code_pro

  install_firacode_nerd=false
  install_symbols_nerd=false
  symbols_fallback_config="$XDG_CONFIG_HOME/fontconfig/conf.d/10-nerd-font-symbols.conf"
  font_family_is_available 'FiraCode Nerd Font Mono' || install_firacode_nerd=true
  if ! font_family_is_available 'Symbols Nerd Font Mono' ||
     ! grep -Fq '<family>Symbols Nerd Font Mono</family>' "$symbols_fallback_config" 2>/dev/null; then
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
    install_nerd_font_fallback_config "$fallback_config"
  fi

  rm -rf "$temp_dir"
  fc-cache -f
  font_family_is_available 'FiraCode Nerd Font Mono' || fail 'FiraCode Nerd Font Mono was not installed'
  font_family_is_available 'Symbols Nerd Font Mono' || fail 'Symbols Nerd Font Mono was not installed'
  grep -Fq '<family>Symbols Nerd Font Mono</family>' "$symbols_fallback_config" ||
    fail 'Nerd Fonts monospace symbols fallback configuration was not installed'
}

verify_requested_fonts() {
  if ! command -v fc-list >/dev/null 2>&1; then
    warn 'fontconfig is unavailable; skipping font-family verification'
    return
  fi

  if command -v fc-cache >/dev/null 2>&1; then
    fc-cache -f
  fi
  for family_name in 'JetBrains Mono' 'Cascadia Code' 'Source Code Pro' Hack 'Symbols Nerd Font Mono'; do
    font_family_is_available "$family_name" || fail "$family_name was not installed"
  done
}

install_fonts() {
  info "Ensuring workstation fonts are installed on $PLATFORM"
  case $PLATFORM in
    macos)
      # Yazi uses Nerd Font icons. The symbols-only family can be selected as a
      # terminal fallback without replacing the primary text font.
      ensure_brew_casks \
        font-cascadia-code \
        font-fira-code \
        font-fira-code-nerd-font \
        font-hack \
        font-jetbrains-mono \
        font-source-code-pro \
        font-symbols-only-nerd-font
      ;;
    ubuntu)
      install_ubuntu_fonts
      ;;
    arch)
      ensure_arch_packages \
        adobe-source-code-pro-fonts \
        fontconfig \
        ttf-cascadia-code \
        ttf-fira-code \
        ttf-firacode-nerd \
        ttf-hack \
        ttf-jetbrains-mono \
        ttf-nerd-fonts-symbols \
        ttf-nerd-fonts-symbols-mono
      install_packaged_nerd_font_fallback_config
      ;;
    omarchy)
      # Keep Omarchy's selected system font and install the families only.
      ensure_omarchy_packages \
        adobe-source-code-pro-fonts \
        fontconfig \
        ttf-cascadia-code \
        ttf-fira-code \
        ttf-firacode-nerd \
        ttf-hack \
        ttf-jetbrains-mono \
        ttf-nerd-fonts-symbols \
        ttf-nerd-fonts-symbols-mono
      install_packaged_nerd_font_fallback_config
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
  verify_requested_fonts
}

main "$@"

#!/bin/sh

set -eu

BOOTSTRAP_DIR=$(CDPATH= cd -- "$(dirname -- "$0")" && pwd)
# shellcheck source=lib.sh
. "$BOOTSTRAP_DIR/lib.sh"

ONEPASSWORD_FINGERPRINT=3FEF9748469ADBE15DA7CA80AC2D62742012EA22
ONEPASSWORD_KEY_URL=https://downloads.1password.com/linux/keys/1password.asc
CLI_ONLY=false

usage() {
  printf '%s\n' \
    'Usage: 1password.sh [--cli-only]' \
    '' \
    'Install missing 1Password desktop and CLI packages.' \
    'Use --cli-only on a headless machine to install only op.' \
    'Arch and Omarchy ARM64 use signature-verified vendor releases.'
}

parse_arguments() {
  case ${1:-} in
    -h|--help) usage; exit 0 ;;
    --cli-only) CLI_ONLY=true; [ "$#" -eq 1 ] || fail "unknown option: $2" ;;
    '') [ "$#" -eq 0 ] || fail "unknown option: $2" ;;
    *) fail "unknown option: $1" ;;
  esac
}

need_desktop() {
  [ "$CLI_ONLY" = false ] || return 1
  case $PLATFORM in
    macos)
      if [ -d /Applications/1Password.app ] || [ -d "$HOME/Applications/1Password.app" ] ||
         brew list --cask 1password >/dev/null 2>&1; then
        return 1
      fi
      ;;
    ubuntu) dpkg-query -W -f='${Status}' 1password 2>/dev/null | grep -q 'install ok installed' && return 1 ;;
    arch|omarchy)
      if pacman -Q 1password >/dev/null 2>&1 || [ -x /opt/1Password/1password ]; then
        return 1
      fi
      ;;
  esac
  return 0
}

need_cli() {
  ! command -v op >/dev/null 2>&1
}

verify_vendor_key() {
  key_file=$1
  fingerprint=$(gpg --show-keys --with-colons "$key_file" 2>/dev/null |
    awk -F: '$1 == "pub" { keys++ } $1 == "fpr" && !fingerprint { fingerprint = $10 } END { if (keys == 1) print fingerprint }')
  [ "$fingerprint" = "$ONEPASSWORD_FINGERPRINT" ] ||
    fail "1Password signing key fingerprint mismatch: ${fingerprint:-not available}"
}

install_ubuntu_repository() {
  repo_arch=$(dpkg --print-architecture)
  case $repo_arch in
    amd64|arm64) ;;
    *) fail "1Password APT repository is not supported on $repo_arch" ;;
  esac
  if [ "$repo_arch" != amd64 ] && need_desktop; then
    fail '1Password desktop is not in the Ubuntu ARM64 APT repository; use --cli-only or install the vendor-signed ARM64 tarball manually'
  fi
  ensure_ubuntu_packages ca-certificates curl gnupg
  require_command gpg

  keyring=/usr/share/keyrings/1password-archive-keyring.gpg
  source_list=/etc/apt/sources.list.d/1password.list
  preferences=/etc/apt/preferences.d/1password
  policy_dir=/etc/debsig/policies/AC2D62742012EA22
  debsig_dir=/usr/share/debsig/keyrings/AC2D62742012EA22
  source_entry="deb [arch=$repo_arch signed-by=$keyring] https://downloads.1password.com/linux/debian/$repo_arch stable main"

  temp_dir=$(mktemp -d "${TMPDIR:-/tmp}/dotfiles-onepassword.XXXXXX")
  trap 'rm -rf "$temp_dir"' EXIT HUP INT TERM
  curl --proto '=https' --proto-redir '=https' -fsSL "$ONEPASSWORD_KEY_URL" -o "$temp_dir/1password.asc"
  verify_vendor_key "$temp_dir/1password.asc"

  if [ -e "$keyring" ]; then
    verify_vendor_key "$keyring"
  else
    gpg --batch --yes --dearmor -o "$temp_dir/keyring.gpg" "$temp_dir/1password.asc"
    sudo install -m 0644 "$temp_dir/keyring.gpg" "$keyring"
  fi
  if [ -e "$source_list" ]; then
    printf '%s\n' "$source_entry" | cmp -s - "$source_list" || fail "unexpected 1Password APT source: $source_list"
  else
    printf '%s\n' "$source_entry" | sudo tee "$source_list" >/dev/null
  fi

  # Prefer the vendor for these two names, and forbid falling back to other
  # repositories if the vendor does not publish a package for this host.
  printf '%s\n' \
    'Package: 1password 1password-cli' \
    'Pin: origin "downloads.1password.com"' \
    'Pin-Priority: 990' \
    '' \
    'Package: 1password 1password-cli' \
    'Pin: version *' \
    'Pin-Priority: -1' >"$temp_dir/preferences"
  if [ -e "$preferences" ]; then
    cmp -s "$temp_dir/preferences" "$preferences" || fail "unexpected 1Password APT preferences: $preferences"
  else
    sudo install -m 0644 "$temp_dir/preferences" "$preferences"
  fi

  # Follow the vendor's debsig policy as well as APT repository signature checks.
  if [ ! -f "$policy_dir/1password.pol" ]; then
    curl --proto '=https' --proto-redir '=https' -fsSL https://downloads.1password.com/linux/debian/debsig/1password.pol -o "$temp_dir/1password.pol"
    sudo install -d -m 0755 "$policy_dir"
    sudo install -m 0644 "$temp_dir/1password.pol" "$policy_dir/1password.pol"
  fi
  if [ -e "$debsig_dir/debsig.gpg" ]; then
    verify_vendor_key "$debsig_dir/debsig.gpg"
  else
    gpg --batch --yes --dearmor -o "$temp_dir/debsig.gpg" "$temp_dir/1password.asc"
    sudo install -d -m 0755 "$debsig_dir"
    sudo install -m 0644 "$temp_dir/debsig.gpg" "$debsig_dir/debsig.gpg"
  fi
  rm -rf "$temp_dir"
  trap - EXIT HUP INT TERM
}

install_macos() {
  if need_desktop; then
    ensure_brew_casks 1password
  fi
  if need_cli; then
    ensure_brew_casks 1password-cli
  fi
}

verify_macos_signature() {
  signed_path=$1
  label=$2
  codesign --verify --deep --strict "$signed_path" || fail "$label code signature is invalid: $signed_path"
  team_id=$(codesign -dv --verbose=2 "$signed_path" 2>&1 | awk -F= '$1 == "TeamIdentifier" { print $2; exit }')
  [ "$team_id" = 2BUA8C4S2C ] || fail "$label is not signed by 1Password: $signed_path"
}

verify_macos_installation() {
  app_path=""
  if [ -d /Applications/1Password.app ]; then
    app_path=/Applications/1Password.app
  elif [ -d "$HOME/Applications/1Password.app" ]; then
    app_path="$HOME/Applications/1Password.app"
  fi
  if [ "$CLI_ONLY" = false ]; then
    if [ -n "$app_path" ]; then
      verify_macos_signature "$app_path" '1Password desktop'
    else
      warn '1Password desktop is not in a standard Applications directory; its signature could not be checked'
    fi
  fi
  verify_macos_signature "$(command -v op)" '1Password CLI'
}

current_cli_release_version() {
  release_file=$1
  curl --proto '=https' --proto-redir '=https' -fsSL --max-time 15 \
    https://app-updates.agilebits.com/check/1/0/CLI2/en/2000001/N -o "$release_file" &&
    jq -er '.version | select(type == "string" and test("^[0-9]+[.][0-9]+[.][0-9]+$"))' "$release_file"
}

warn_if_outdated_cli() {
  installed_version=$1
  if ! command -v curl >/dev/null 2>&1 || ! command -v jq >/dev/null 2>&1; then
    warn 'curl and jq are needed to check the current 1Password CLI release; skipping version comparison'
    return
  fi
  release_file=$(mktemp "${TMPDIR:-/tmp}/dotfiles-onepassword-version.XXXXXX")
  if ! latest_version=$(current_cli_release_version "$release_file" 2>/dev/null); then
    warn 'could not check the current 1Password CLI release version'
    rm -f "$release_file"
    return
  fi
  rm -f "$release_file"
  if awk -v installed="$installed_version" -v latest="$latest_version" '
    BEGIN {
      if (installed !~ /^[0-9]+[.][0-9]+[.][0-9]+$/) exit 1
      split(installed, a, "."); split(latest, b, ".")
      for (i = 1; i <= 3; i++) {
        if (a[i] + 0 < b[i] + 0) exit 0
        if (a[i] + 0 > b[i] + 0) exit 1
      }
      exit 1
    }
  '; then
    warn "1Password CLI $installed_version is older than the vendor's stable $latest_version; update it manually or through your package manager"
  fi
}

verify_ubuntu_candidate() {
  package_name=$1
  policy=$(apt-cache policy "$package_name") || fail "cannot inspect APT candidate for $package_name"
  candidate=$(printf '%s\n' "$policy" | awk '$1 == "Candidate:" { print $2; exit }')
  if [ -z "$candidate" ] || [ "$candidate" = '(none)' ]; then
    fail "no APT candidate for $package_name"
  fi

  # APT chooses a version by pin priority, but may download an identical
  # version from another source. Reject ambiguous candidate versions too.
  candidate_sources=$(printf '%s\n' "$policy" | awk -v version="$candidate" '
    $1 == version || ($1 == "***" && $2 == version) { in_version = 1; next }
    in_version && $2 ~ /^-?[0-9]+$/ { exit }
    in_version && $1 ~ /^-?[0-9]+$/ && $2 != "/var/lib/dpkg/status" { print $2 }
  ')
  expected_source="https://downloads.1password.com/linux/debian/$repo_arch"
  [ "$candidate_sources" = "$expected_source" ] ||
    fail "$package_name candidate $candidate is not exclusive to $expected_source (sources: ${candidate_sources:-none})"
}

install_ubuntu() {
  if ! need_cli && ! need_desktop; then
    return
  fi
  if need_cli && dpkg-query -W -f='${Status}' 1password-cli 2>/dev/null | grep -q 'install ok installed'; then
    fail '1password-cli is installed but op is not in PATH; check the installation rather than upgrading it'
  fi
  install_ubuntu_repository
  set --
  if need_desktop; then
    set -- 1password
  fi
  if need_cli; then
    set -- "$@" 1password-cli
  fi
  sudo apt-get update
  for package_name in "$@"; do
    verify_ubuntu_candidate "$package_name"
  done
  sudo apt-get install -y "$@"
}

vendor_architecture() {
  case $(uname -m) in
    x86_64|amd64) vendor_arch=x86_64; cli_arch=amd64 ;;
    aarch64|arm64) vendor_arch=aarch64; cli_arch=arm64 ;;
    *) fail "1Password does not publish a supported Linux release for $(uname -m)" ;;
  esac
}

verify_vendor_signature() {
  gpgv --keyring "$temp_dir/vendor.gpg" "$1" "$2" || fail "1Password signature verification failed for $2"
}

install_vendor_desktop() {
  archive="$temp_dir/1password.tar.gz"
  download_base="https://downloads.1password.com/linux/tar/stable/$vendor_arch/1password-latest.tar.gz"
  info "Installing signed 1Password desktop release for $vendor_arch"
  curl --proto '=https' --proto-redir '=https' -fsSL "$download_base" -o "$archive"
  curl --proto '=https' --proto-redir '=https' -fsSL "$download_base.sig" -o "$archive.sig"
  verify_vendor_signature "$archive.sig" "$archive"

  mkdir "$temp_dir/extracted"
  tar -xzf "$archive" -C "$temp_dir/extracted"
  extracted_dir=$(find "$temp_dir/extracted" -mindepth 1 -maxdepth 1 -type d -name '1password-*' -print -quit)
  if [ -z "$extracted_dir" ] || [ ! -f "$extracted_dir/after-install.sh" ]; then
    fail '1Password desktop archive has an unexpected layout'
  fi
  if [ -e /opt/1Password ] || [ -L /opt/1Password ]; then
    fail '/opt/1Password already exists; refusing to overwrite it'
  fi
  sudo install -d -m 0755 /opt/1Password
  sudo cp -R "$extracted_dir"/. /opt/1Password/
  sudo chown -R root:root /opt/1Password
  sudo /opt/1Password/after-install.sh
  cmp -s "$extracted_dir/1password" /opt/1Password/1password ||
    fail 'installed 1Password desktop binary differs from the signed archive'
}

install_vendor_cli() {
  cli_version=$(current_cli_release_version "$temp_dir/cli-release.json") ||
    fail 'could not determine the current stable 1Password CLI version'
  cli_zip="op_linux_${cli_arch}_v${cli_version}.zip"
  info "Installing signed 1Password CLI $cli_version for $cli_arch"
  curl --proto '=https' --proto-redir '=https' -fsSL \
    "https://cache.agilebits.com/dist/1P/op2/pkg/v${cli_version}/$cli_zip" -o "$temp_dir/cli.zip"
  unzip -p "$temp_dir/cli.zip" op >"$temp_dir/op"
  unzip -p "$temp_dir/cli.zip" op.sig >"$temp_dir/op.sig"
  if [ ! -s "$temp_dir/op" ] || [ ! -s "$temp_dir/op.sig" ]; then
    fail '1Password CLI archive is incomplete'
  fi
  verify_vendor_signature "$temp_dir/op.sig" "$temp_dir/op"
  if [ -e /usr/local/bin/op ] || [ -L /usr/local/bin/op ]; then
    fail '/usr/local/bin/op already exists; refusing to overwrite it'
  fi
  sudo install -m 0755 "$temp_dir/op" /usr/local/bin/op
  cmp -s "$temp_dir/op" /usr/local/bin/op || fail 'installed op differs from the signed binary'
  refresh_standard_paths
  [ "$(/usr/local/bin/op --version)" = "$cli_version" ] ||
    fail "installed op version does not match the signed release $cli_version"
}

configure_vendor_cli_integration() {
  # Only change the root-owned binary installed by this script, not another op.
  if [ "$(command -v op)" = /usr/local/bin/op ] && [ "$(stat -c %u /usr/local/bin/op)" = 0 ]; then
    sudo groupadd -f onepassword-cli
    sudo chgrp onepassword-cli /usr/local/bin/op
    sudo chmod g+s /usr/local/bin/op
  else
    warn '1Password CLI was installed elsewhere; configure desktop integration manually if needed'
  fi
}

install_vendor_linux() {
  if ! need_cli && ! need_desktop; then
    return
  fi
  vendor_architecture
  if pacman -Q 1password >/dev/null 2>&1 || pacman -Q 1password-cli >/dev/null 2>&1; then
    fail '1Password is pacman-managed; refusing to mix vendor files with package-managed installation'
  fi
  if need_desktop && { [ -e /opt/1Password ] || [ -L /opt/1Password ]; }; then
    fail '/opt/1Password already exists; refusing to overwrite it'
  fi
  if need_desktop && { [ -e /usr/bin/1password ] || [ -L /usr/bin/1password ]; }; then
    fail '/usr/bin/1password already exists; refusing to replace the launcher'
  fi
  if need_desktop && { [ -e /usr/bin/1password-mcp ] || [ -L /usr/bin/1password-mcp ]; }; then
    fail '/usr/bin/1password-mcp already exists; refusing to replace the launcher'
  fi
  if need_cli && { [ -e /usr/local/bin/op ] || [ -L /usr/local/bin/op ]; }; then
    fail '/usr/local/bin/op already exists; refusing to overwrite it'
  fi
  case $PLATFORM in
    arch) ensure_arch_packages ca-certificates curl gnupg jq unzip ;;
    omarchy) ensure_omarchy_packages ca-certificates curl gnupg jq unzip ;;
  esac
  require_command gpgv
  temp_dir=$(mktemp -d "${TMPDIR:-/tmp}/dotfiles-onepassword-vendor.XXXXXX")
  trap 'rm -rf "$temp_dir"' EXIT HUP INT TERM
  curl --proto '=https' --proto-redir '=https' -fsSL "$ONEPASSWORD_KEY_URL" -o "$temp_dir/1password.asc"
  verify_vendor_key "$temp_dir/1password.asc"
  gpg --batch --yes --dearmor -o "$temp_dir/vendor.gpg" "$temp_dir/1password.asc"

  if need_desktop; then
    install_vendor_desktop
  fi
  if need_cli; then
    install_vendor_cli
  fi
  if [ "$CLI_ONLY" = false ]; then
    configure_vendor_cli_integration
  fi
  rm -rf "$temp_dir"
  trap - EXIT HUP INT TERM
}

install_omarchy() {
  case $(uname -m) in
    x86_64)
      if { need_cli || need_desktop; } &&
         { [ -x /opt/1Password/1password ] || [ -x /usr/local/bin/op ]; }; then
        fail '1Password vendor files are present; refusing to mix them with Omarchy packages'
      fi
      if need_desktop; then
        if need_cli; then
          ensure_omarchy_packages 1password 1password-cli
        else
          ensure_omarchy_packages 1password
        fi
      elif need_cli; then
        ensure_omarchy_packages 1password-cli
      fi
      ;;
    aarch64|arm64) install_vendor_linux ;;
    *) fail "unsupported Omarchy architecture: $(uname -m)" ;;
  esac
}

main() {
  parse_arguments "$@"
  bootstrap_init
  info "Ensuring 1Password is installed on $PLATFORM"
  case $PLATFORM in
    macos) install_macos ;;
    ubuntu) install_ubuntu ;;
    arch) install_vendor_linux ;;
    omarchy) install_omarchy ;;
  esac
  require_command op
  if [ "$CLI_ONLY" = false ] && need_desktop; then
    fail '1Password desktop was not installed'
  fi
  if [ "$PLATFORM" = macos ]; then
    verify_macos_installation
  fi
  installed_cli_version=$(op --version)
  warn_if_outdated_cli "$installed_cli_version"
  printf '1Password CLI: %s\n' "$installed_cli_version"
  if [ "$CLI_ONLY" = false ]; then
    printf '1Password desktop: installed (sign in interactively to use it)\n'
  fi
}

main "$@"

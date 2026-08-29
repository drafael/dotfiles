#!/bin/sh

set -eu

DOTFILES_DIR=$(CDPATH= cd -- "$(dirname -- "$0")/.." && pwd)
EXPECTED_DOTFILES_DIR="$HOME/.dotfiles"
BACKUP_BASE="$HOME/.dotfiles-backups"
BACKUP_DIR=""
PLATFORM=""
XDG_CONFIG_HOME=${XDG_CONFIG_HOME:-"$HOME/.config"}

# Keep user-installed coding agents and Ubuntu's managed Neovim ahead of
# system paths during this run. env.sh applies the same order to new shells.
PATH="$HOME/.local/bin:$HOME/.opencode/bin:$HOME/.local/share/pi-node/current/bin:$PATH"
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
  mkdir -p "$(dirname "$backup_destination")"
  mv "$backup_source" "$backup_destination"
  printf 'backed up %s -> %s\n' "$backup_source" "$backup_destination"
}

backup_copy() {
  copy_source=$1
  copy_relative=${copy_source#"$HOME"/}
  create_backup_dir
  copy_destination="$BACKUP_DIR/$copy_relative"
  mkdir -p "$(dirname "$copy_destination")"
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

  mkdir -p "$(dirname "$link_destination")"
  ln -s "$link_source" "$link_destination"
  printf 'linked     %s -> %s\n' "$link_destination" "$link_source"
}

download_installer() {
  label=$1
  shell_command=$2
  url=$3
  shift 3

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

ensure_homebrew() {
  require_command curl
  if command -v brew >/dev/null 2>&1; then
    return
  fi

  download_installer Homebrew /bin/bash https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh

  if [ -x /opt/homebrew/bin/brew ]; then
    eval "$(/opt/homebrew/bin/brew shellenv)"
  elif [ -x /usr/local/bin/brew ]; then
    eval "$(/usr/local/bin/brew shellenv)"
  else
    fail 'Homebrew installed, but brew is not available in a standard location'
  fi
}

install_macos_packages() {
  ensure_homebrew
  info 'Installing macOS packages'
  brew install git git-lfs gh glab mise starship tmux neovim fzf fd zoxide ripgrep openjdk@25 maven gradle
  brew install --cask ghostty

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

install_starship() {
  if command -v starship >/dev/null 2>&1; then
    return
  fi
  mkdir -p "$HOME/.local/bin"
  download_installer Starship sh https://starship.rs/install.sh -y -b "$HOME/.local/bin"
}

install_ubuntu_glab() {
  info 'Installing current GitLab CLI for Ubuntu'
  sudo systemctl enable --now snapd.socket >/dev/null 2>&1 || warn 'could not start snapd.socket; snap may already be active'
  if ! sudo snap list glab >/dev/null 2>&1; then
    sudo snap install glab
  fi
  sudo snap connect glab:ssh-keys >/dev/null 2>&1 || warn 'could not grant glab access to SSH keys'
  sudo snap connect glab:password-manager-service >/dev/null 2>&1 || warn 'could not connect glab to the desktop keyring; it may use plaintext credential storage'
  PATH="/snap/bin:$PATH"
  export PATH
}

install_ubuntu_packages() {
  info 'Enabling Ubuntu package repositories'
  sudo apt-get update
  sudo apt-get install -y software-properties-common curl ca-certificates xz-utils python3 snapd
  sudo add-apt-repository -y universe
  sudo apt-get update

  info 'Installing Ubuntu packages'
  sudo apt-get install -y git git-lfs gh zsh tmux fzf fd-find zoxide ripgrep kitty wl-clipboard build-essential unzip openjdk-25-jdk maven
  install_ubuntu_glab
  install_starship
  install_ubuntu_neovim
  link_path /usr/bin/fdfind "$HOME/.local/bin/fd"
}

install_arch_packages() {
  info 'Installing Arch Linux packages'
  sudo pacman -S --needed --noconfirm git git-lfs github-cli glab curl zsh mise starship tmux neovim fzf fd zoxide ripgrep ghostty wl-clipboard base-devel unzip jdk25-openjdk maven gradle
}

install_omarchy_packages() {
  info 'Checking Omarchy packages'
  # Omarchy already provides a lazy gh launcher and names its configured
  # Neovim package "nvim". Install glab as the missing Git host CLI.
  omarchy pkg add git git-lfs glab mise-bin tmux nvim fzf fd zoxide ripgrep starship wl-clipboard base-devel unzip jdk25-openjdk maven gradle
  command -v gh >/dev/null 2>&1 || omarchy-mise-install gh
}

install_packages() {
  case $PLATFORM in
    macos) install_macos_packages ;;
    ubuntu) install_ubuntu_packages ;;
    arch) install_arch_packages ;;
    omarchy) install_omarchy_packages ;;
  esac
}

install_mise() {
  if command -v mise >/dev/null 2>&1; then
    return
  fi
  download_installer mise sh https://mise.run
  PATH="$HOME/.local/bin:$PATH"
  export PATH
  require_command mise
}

install_node_tooling() {
  install_mise
  info 'Installing the latest Node.js LTS and TypeScript tools'
  mise use --global node@lts
  PATH="$HOME/.local/share/mise/shims:$PATH"
  export PATH
  hash -r 2>/dev/null || true
  require_command node
  require_command npm
  npm install --global typescript@latest typescript-language-server@latest tsx@latest
  mise reshim
}

install_agents() {
  if [ "$PLATFORM" = omarchy ]; then
    info 'Keeping Omarchy coding-agent launchers'
    command -v codex >/dev/null 2>&1 || omarchy-mise-install codex
    return
  fi

  if ! command -v claude >/dev/null 2>&1; then
    download_installer 'Claude Code' /bin/bash https://claude.ai/install.sh
  fi

  if ! command -v opencode >/dev/null 2>&1; then
    download_installer OpenCode /bin/bash https://opencode.ai/install --no-modify-path
  fi

  if ! command -v pi >/dev/null 2>&1; then
    info 'Installing Pi'
    npm install --global --ignore-scripts --min-release-age=0 --no-fund --no-audit @earendil-works/pi-coding-agent@latest
    mise reshim
  fi

  if ! command -v codex >/dev/null 2>&1; then
    info 'Installing Codex CLI'
    npm install --global @openai/codex@latest
    mise reshim
  fi
}

configure_zsh_platform() {
  link_path "$DOTFILES_DIR/.zshrc" "$HOME/.zshrc"

  zsh_path=$(command -v zsh)
  if [ "${SHELL:-}" != "$zsh_path" ]; then
    info "Setting the login shell to $zsh_path"
    if [ "$PLATFORM" = macos ]; then
      chsh -s "$zsh_path" || warn "could not change the login shell; run: chsh -s $zsh_path"
    else
      login_user=$(id -un)
      sudo chsh -s "$zsh_path" "$login_user" || warn "could not change the login shell; run: sudo chsh -s $zsh_path $login_user"
    fi
  fi
}

configure_omarchy_bash() {
  bashrc="$HOME/.bashrc"
  marker='# >>> drafael dotfiles >>>'

  end_marker='# <<< drafael dotfiles <<<'
  if grep -Fq "$marker" "$bashrc" 2>/dev/null &&
     grep -Fq "$end_marker" "$bashrc" 2>/dev/null &&
     grep -Fq '[ -f "$DOTFILES_DIR/env.sh" ] && . "$DOTFILES_DIR/env.sh"' "$bashrc" 2>/dev/null &&
     grep -Fq '[ -f "$DOTFILES_DIR/aliases.sh" ] && . "$DOTFILES_DIR/aliases.sh"' "$bashrc" 2>/dev/null &&
     grep -Fq '[ -f "$DOTFILES_DIR/linux.sh" ] && . "$DOTFILES_DIR/linux.sh"' "$bashrc" 2>/dev/null; then
    printf 'configured %s\n' "$bashrc"
    return
  fi

  if [ -e "$bashrc" ]; then
    backup_copy "$bashrc"
    cleaned_bashrc=$(mktemp "${TMPDIR:-/tmp}/dotfiles-bashrc.XXXXXX")
    awk -v start="$marker" -v finish="$end_marker" '
      $0 == start { skipping = 1; next }
      $0 == finish { skipping = 0; next }
      !skipping { print }
    ' "$bashrc" >"$cleaned_bashrc"
    cat "$cleaned_bashrc" >"$bashrc"
    rm -f "$cleaned_bashrc"
  fi
  cat >>"$bashrc" <<'EOF'

# >>> drafael dotfiles >>>
export DOTFILES_DIR="$HOME/.dotfiles"
[ -f "$DOTFILES_DIR/env.sh" ] && . "$DOTFILES_DIR/env.sh"
[ -f "$DOTFILES_DIR/aliases.sh" ] && . "$DOTFILES_DIR/aliases.sh"
[ -f "$DOTFILES_DIR/linux.sh" ] && . "$DOTFILES_DIR/linux.sh"
# <<< drafael dotfiles <<<
EOF
  printf 'configured %s\n' "$bashrc"
}

link_configuration() {
  info 'Linking configuration'
  link_path "$DOTFILES_DIR/.gitconfig" "$HOME/.gitconfig"
  link_path "$DOTFILES_DIR/.gitignore_global" "$HOME/.gitignore_global"
  link_path "$DOTFILES_DIR/.config/tmux" "$HOME/.config/tmux"
  link_path "$DOTFILES_DIR/.config/nvim" "$HOME/.config/nvim"
  link_path "$DOTFILES_DIR/.config/lazygit/config.yml" "$XDG_CONFIG_HOME/lazygit/config.yml"
  link_path "$DOTFILES_DIR/.config/tig/config" "$XDG_CONFIG_HOME/tig/config"

  case $PLATFORM in
    macos)
      configure_zsh_platform
      link_path "$DOTFILES_DIR/.config/ghostty" "$HOME/.config/ghostty"
      ;;
    arch)
      configure_zsh_platform
      link_path "$DOTFILES_DIR/.config/ghostty/linux.conf" "$HOME/.config/ghostty/config"
      ;;
    ubuntu)
      configure_zsh_platform
      link_path "$DOTFILES_DIR/.config/kitty/linux.conf" "$HOME/.config/kitty/kitty.conf"
      ;;
    omarchy)
      configure_omarchy_bash
      ;;
  esac
}

set_java_environment() {
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

  if [ -n "${JAVA_HOME:-}" ] && [ -x "$JAVA_HOME/bin/java" ]; then
    PATH="$JAVA_HOME/bin:$PATH"
    export JAVA_HOME PATH
  fi
}

first_line() {
  "$@" 2>&1 | awk 'NF { print; exit }'
}

verify_installation() {
  set_java_environment
  info 'Installed versions'

  for command_name in git git-lfs gh glab mise node npm tsc typescript-language-server tsx tmux nvim fzf fd zoxide rg java javac mvn; do
    if command -v "$command_name" >/dev/null 2>&1; then
      case $command_name in
        git) first_line git --version ;;
        git-lfs) first_line git lfs version ;;
        gh)
          if [ "$PLATFORM" = omarchy ]; then
            printf 'gh: Omarchy lazy launcher available\n'
          else
            first_line gh --version
          fi
          ;;
        glab) first_line glab --version ;;
        mise) first_line mise --version ;;
        node) first_line node --version ;;
        npm) first_line npm --version ;;
        tsc) first_line tsc --version ;;
        typescript-language-server) first_line typescript-language-server --version ;;
        tsx) first_line tsx --version ;;
        tmux) first_line tmux -V ;;
        nvim) first_line nvim --version ;;
        fzf) first_line fzf --version ;;
        fd) first_line fd --version ;;
        zoxide) first_line zoxide --version ;;
        rg) first_line rg --version ;;
        java) first_line java -version ;;
        javac) first_line javac -version ;;
        mvn) first_line mvn -version ;;
      esac
    else
      warn "$command_name is not available"
    fi
  done

  if [ "$PLATFORM" != ubuntu ] && command -v gradle >/dev/null 2>&1; then
    first_line gradle --version
  fi

  if [ "$PLATFORM" = omarchy ]; then
    printf 'Claude Code, Codex, OpenCode, and Pi will install through Omarchy when first launched.\n'
  else
    for agent in claude codex opencode pi; do
      if command -v "$agent" >/dev/null 2>&1; then
        printf '%s: installed\n' "$agent"
      else
        warn "$agent is not available in the current PATH"
      fi
    done
  fi
}

main() {
  [ "$(id -u)" -ne 0 ] || fail 'run bootstrap as your normal user, not root'
  [ "$DOTFILES_DIR" = "$EXPECTED_DOTFILES_DIR" ] || fail "clone this repository to $EXPECTED_DOTFILES_DIR before running bootstrap"
  detect_platform

  info "Bootstrapping $PLATFORM from $DOTFILES_DIR"
  install_packages
  require_command curl
  install_node_tooling
  install_agents
  link_configuration
  verify_installation

  info 'Next steps'
  if [ "$PLATFORM" = omarchy ]; then
    printf '%s\n' '1. Open a new terminal.' '2. Run claude, codex, opencode, and pi once to install and authenticate them.'
  else
    printf '%s\n' '1. Run: exec zsh' '2. Run claude, codex, opencode, and pi to authenticate them.'
  fi
  printf '%s\n' '3. Add your Git identity to ~/.gitconfig.local.'
  if [ -n "$BACKUP_DIR" ]; then
    printf 'Existing files were saved under %s\n' "$BACKUP_DIR"
  fi
}

main "$@"

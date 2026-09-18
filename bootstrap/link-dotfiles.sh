#!/bin/sh

set -eu

BOOTSTRAP_DIR=$(CDPATH= cd -- "$(dirname -- "$0")" && pwd)
# shellcheck source=lib.sh
. "$BOOTSTRAP_DIR/lib.sh"

SOURCE_CONFIG_DIR="$DOTFILES_DIR/.config"

usage() {
  printf '%s\n' \
    'Usage: link-dotfiles.sh' \
    '' \
    'Link repository dotfiles, backing up conflicting destinations.'
}

configure_zsh_platform() {
  link_path "$DOTFILES_DIR/.zshrc" "$HOME/.zshrc"

  require_command zsh
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

link_portable_config() {
  mkdir -p "$XDG_CONFIG_HOME"
  for source in "$SOURCE_CONFIG_DIR"/* "$SOURCE_CONFIG_DIR"/.[!.]* "$SOURCE_CONFIG_DIR"/..?*; do
    if [ ! -e "$source" ] && [ ! -L "$source" ]; then
      continue
    fi

    name=${source##*/}
    case $name in
      .DS_Store|ghostty|kitty) continue ;;
    esac
    link_path "$source" "$XDG_CONFIG_HOME/$name"
  done
}

link_terminal_config() {
  case $PLATFORM in
    macos)
      link_path "$SOURCE_CONFIG_DIR/ghostty" "$XDG_CONFIG_HOME/ghostty"
      ;;
    arch)
      ensure_real_directory "$XDG_CONFIG_HOME/ghostty"
      link_path "$SOURCE_CONFIG_DIR/ghostty/linux.conf" "$XDG_CONFIG_HOME/ghostty/config"
      ;;
    ubuntu)
      ensure_real_directory "$XDG_CONFIG_HOME/kitty"
      link_path "$SOURCE_CONFIG_DIR/kitty/linux.conf" "$XDG_CONFIG_HOME/kitty/kitty.conf"
      ;;
    omarchy) ;;
  esac
}

link_root_dotfiles() {
  link_path "$DOTFILES_DIR/.gitconfig" "$HOME/.gitconfig"
  link_path "$DOTFILES_DIR/.gitignore_global" "$HOME/.gitignore_global"

  case $PLATFORM in
    macos|ubuntu|arch) configure_zsh_platform ;;
    omarchy) configure_omarchy_bash ;;
  esac
}

main() {
  case ${1:-} in
    -h|--help) usage; exit 0 ;;
    '') ;;
    *) fail "unknown option: $1" ;;
  esac

  bootstrap_init
  [ -d "$SOURCE_CONFIG_DIR" ] || fail "configuration directory not found: $SOURCE_CONFIG_DIR"

  info 'Linking portable configuration'
  link_portable_config
  link_terminal_config
  link_root_dotfiles

  if [ -n "$BACKUP_DIR" ]; then
    printf 'Existing files were saved under %s\n' "$BACKUP_DIR"
  fi
}

main "$@"

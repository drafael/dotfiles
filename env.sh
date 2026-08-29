
if locale -a 2>/dev/null | grep -Eiq '^en_US[.]utf-?8$'; then
  export LANG="en_US.UTF-8"
  export LC_ALL="en_US.UTF-8"
elif locale -a 2>/dev/null | grep -Eiq '^C[.]utf-?8$'; then
  export LANG="C.UTF-8"
  export LC_ALL="C.UTF-8"
fi

export EDITOR=nvim

# Use the same XDG configuration layout on macOS and Linux.
export XDG_CONFIG_HOME="${XDG_CONFIG_HOME:-$HOME/.config}"

# Ignore duplicate commands in the history
export HISTCONTROL=ignoredups

# Increase the maximum number of lines contained in the history file (default is 500)
export HISTFILESIZE=10000

# Increase the maximum number of commands to remember (default is 500)
export HISTSIZE=10000

# Don't clear the screen after quitting a manual page
export MANPAGER="less -X"

# Keep user-managed tools ahead of system packages without duplicating entries
# when this file is sourced more than once.
for path_entry in \
  "/snap/bin" \
  "$HOME/.local/share/pi-node/current/bin" \
  "$HOME/.opencode/bin" \
  "$HOME/.local/bin" \
  "$DOTFILES_DIR/bin" \
  "$HOME/.local/share/mise/shims"
do
  if [ -d "$path_entry" ]; then
    case ":$PATH:" in
      *":$path_entry:"*) ;;
      *) PATH="$path_entry:$PATH" ;;
    esac
  fi
done
unset path_entry

export GOPATH="$HOME/code/go"
case ":$PATH:" in
  *":$GOPATH/bin:"*) ;;
  *) PATH="$GOPATH/bin:$PATH" ;;
esac
export PATH

export STARSHIP_CONFIG="$DOTFILES_DIR/.config/starship.toml"
export YAZI_CONFIG_HOME="$DOTFILES_DIR/.config/yazi"
export MC_SKIN="$DOTFILES_DIR/.config/mc/catppuccin.ini"

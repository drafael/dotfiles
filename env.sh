
export LANG="en_US.UTF-8"
export LC_ALL="en_US.UTF-8"

export EDITOR=vim

# Ignore duplicate commands in the history
export HISTCONTROL=ignoredups

# Increase the maximum number of lines contained in the history file (default is 500)
export HISTFILESIZE=10000

# Increase the maximum number of commands to remember (default is 500)
export HISTSIZE=10000

# Don't clear the screen after quitting a manual page
export MANPAGER="less -X"

export PATH=$PATH:$DOTFILES_DIR/bin

export GOPATH="$HOME/code/go"
export PATH="$GOPATH/bin:$PATH"

#
# Solarized skin for Midnight Commander
#
if [[ $ITERM_PROFILE =~ Solarized ]]; then
  if [ -f $DOTFILES_DIR/.config/mc/solarized.ini ]; then
    export MC_SKIN=$DOTFILES_DIR/.config/mc/solarized.ini
  fi
else
  if [ -f $DOTFILES_DIR/.config/mc/catppuccin.ini ]; then
    export MC_SKIN=$DOTFILES_DIR/.config/mc/catppuccin.ini
  fi
fi

#!/usr/bin/env bash

if [[ -z "$DOTFILES_DIR" ]]; then
  if [[ -d "$HOME/.dotfiles" ]]; then
    export DOTFILES_DIR="$HOME/.dotfiles"
  elif [[ -d "$HOME/dotfiles" ]]; then
    export DOTFILES_DIR="$HOME/dotfiles"
  else
    export DOTFILES_DIR="$HOME"
  fi
fi

if [ -f $DOTFILES_DIR/env.sh ]; then
  source $DOTFILES_DIR/env.sh
fi

if [ -f $DOTFILES_DIR/aliases.sh ]; then
  source $DOTFILES_DIR/aliases.sh
fi

# Bash prompt with Git status
if [ -f $DOTFILES_DIR/bash_prompt.sh ]; then
  source $DOTFILES_DIR/bash_prompt.sh
fi

# OS specific stuff
if [[ $OSTYPE =~ darwin ]]; then
  if [ -f $DOTFILES_DIR/darwin.sh ]; then
    source $DOTFILES_DIR/darwin.sh
  fi

  # [ -f /usr/local/etc/bash_completion ] && . /usr/local/etc/bash_completion
  if [ -f $(brew --prefix)/etc/bash_completion ]; then
    source $(brew --prefix)/etc/bash_completion
  fi
elif [[ $OSTYPE =~ linux ]]; then
  if [ -f $DOTFILES_DIR/linux.sh ]; then
    source $DOTFILES_DIR/linux.sh
  fi
fi

# API tokens and private stuff
if [ -f $HOME/.secrets ]; then
  source $HOME/.secrets
fi

if [ -f $HOME/.bashrc.local ]; then
  source $HOME/.bashrc.local
fi

# Append to the history file when exiting instead of overwriting it
shopt -s histappend

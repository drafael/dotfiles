#!/usr/bin/env zsh

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

# OS specific stuff
if [[ $OSTYPE =~ darwin ]]; then
  if [ -f $DOTFILES_DIR/darwin.sh ]; then
    source $DOTFILES_DIR/darwin.sh
  fi

  # TODO: fix
  if [ -f "/usr/local/opt/zsh-git-prompt/zshrc.sh" ]; then
    source "/usr/local/opt/zsh-git-prompt/zshrc.sh"
  fi

  fpath=(/usr/local/share/zsh-completions $fpath)

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

if [ -f $HOME/.zshrc.local ]; then
  source $HOME/.zshrc.local
fi

#!/usr/bin/env zsh

# echo '.zshrc'

if [[ -z "$DOTFILES_DIR" ]]; then
  if [[ -d "$HOME/.dotfiles" ]]; then
    export DOTFILES_DIR="$HOME/.dotfiles"
  elif [[ -d "$HOME/dotfiles" ]]; then
    export DOTFILES_DIR="$HOME/dotfiles"
  else
    export DOTFILES_DIR="$HOME"
  fi
fi

export ZSH=$DOTFILES_DIR/oh-my-zsh

# See https://github.com/ohmyzsh/ohmyzsh/wiki/Themes
# ZSH_THEME="robbyrussell"
# ZSH_THEME="avit"
# ZSH_THEME="gentoo"
# ZSH_THEME="wezm"

HIST_STAMPS="yyyy-mm-dd"
# CASE_SENSITIVE="true"
HYPHEN_INSENSITIVE="true"
DISABLE_AUTO_UPDATE="true"
# DISABLE_AUTO_TITLE="true"
# ENABLE_CORRECTION="true"
# DISABLE_UNTRACKED_FILES_DIRTY="true"

plugins=(
  git
  # git-prompt
  # git-flow
  docker
  # docker-compose
  kubectl minikube
  # helm
  mvn
  # gradle
  terraform
  # httpie
  # aws
  # python pip pyenv pipenv
  # gem
  # node npm yarn
  zsh-nvm
  # nmap
)

source $ZSH/oh-my-zsh.sh

# Pretty, minimal and fast ZSH prompt
# https://github.com/sindresorhus/pure
unset ZSH_THEME
fpath+=("$DOTFILES_DIR/zsh-prompt")
autoload -U promptinit; promptinit
zstyle :prompt:pure:git:branch color green
zstyle :prompt:pure:git:action color green
zstyle :prompt:pure:prompt:error color red
zstyle :prompt:pure:prompt:success color green
prompt pure


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
elif [[ $OSTYPE =~ linux ]]; then
  if [ -f $DOTFILES_DIR/linux.sh ]; then
    source $DOTFILES_DIR/linux.sh
  fi
fi

# API tokens and private stuff
if [ -f $HOME/.secrets ]; then
  source $HOME/.secrets
fi

if [ -f $HOME/.zshrc.local ]; then
  source $HOME/.zshrc.local
fi

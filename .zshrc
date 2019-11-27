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

export ZSH=$DOTFILES_DIR/oh-my-zsh

# See https://github.com/ohmyzsh/ohmyzsh/wiki/Themes
# ZSH_THEME="robbyrussell"
ZSH_THEME="avit"
# ZSH_THEME="gentoo"
# ZSH_THEME="kphoen"
# ZSH_THEME="wezm"

HIST_STAMPS="yyyy-mm-dd"
# CASE_SENSITIVE="true"
HYPHEN_INSENSITIVE="true"
DISABLE_AUTO_UPDATE="true"
# DISABLE_AUTO_TITLE="true"

# Uncomment the following line if pasting URLs and other text is messed up.
# DISABLE_MAGIC_FUNCTIONS=true

# Uncomment the following line to enable command auto-correction.
# ENABLE_CORRECTION="true"

# Uncomment the following line to display red dots whilst waiting for completion.
# COMPLETION_WAITING_DOTS="true"

# Uncomment the following line if you want to disable marking untracked files
# under VCS as dirty. This makes repository status check for large repositories
# much, much faster.
# DISABLE_UNTRACKED_FILES_DIRTY="true"

# Would you like to use another custom folder than $ZSH/custom?
# ZSH_CUSTOM=/path/to/new-custom-folder

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
  # nmap
)

source $ZSH/oh-my-zsh.sh


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

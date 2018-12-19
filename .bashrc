#!/usr/bin/env bash

if [[ -z "$DOTFILES_DIR" ]]; then
  if [[ -d "$HOME/.dotfiles" ]]; then
    export DOTFILES_DIR="$HOME/.dotfiles"
  elif [[ -d "$HOME/dotfiles" ]]; then
    export DOTFILES_DIR="$HOME/dotfiles"
  else
    export DOTFILES_DIR="$HOME"
    echo "====== Using dotfiles from home dir ======="
  fi
fi

export LANG="en_US.UTF-8"
export LC_ALL="en_US.UTF-8"

# Bash prompt with Git status
if [ -f $DOTFILES_DIR/.bash_prompt ]; then
  source $DOTFILES_DIR/.bash_prompt
fi

export EDITOR=vim

# always use vim instead of vi
alias vi=vim

alias ..="cd .."
alias cd..="cd .."
alias ...="cd ../.."
alias ....="cd ../../.."

# Git
alias g=git
alias gt=git
alias gti=git

# Maven
alias mvnt='mvn test'
alias mvnc='mvn clean'
alias mvnp='mvn package'
alias mvni='mvn install'
alias mvnd='mvn deploy'
alias mvnci='mvn clean install'
alias mvncd='mvn clean deploy'
alias mvnsbr='mvn spring-boot:run'

# Enable aliases to be sudo’ed
alias sudo='sudo '
alias plz=sudo

alias clr=clear
alias clra=clear
alias cler=clear
alias clera=clear

alias j="jobs"
alias h="history"

# Print each PATH entry on a separate line
alias path='echo -e ${PATH//:/\\n}'

# Ignore duplicate commands in the history
export HISTCONTROL=ignoredups

# Increase the maximum number of lines contained in the history file
# (default is 500)
export HISTFILESIZE=10000

# Increase the maximum number of commands to remember
# (default is 500)
export HISTSIZE=10000

# Append to the history file when exiting instead of overwriting it
shopt -s histappend

# Don't clear the screen after quitting a manual page
export MANPAGER="less -X"

# OS specific stuff
if [[ $OSTYPE =~ darwin ]]; then
  if [ -f $DOTFILES_DIR/.bashrc.darwin ]; then
    source $DOTFILES_DIR/.bashrc.darwin
  fi
elif [[ $OSTYPE =~ linux ]]; then
  if [ -f $DOTFILES_DIR/.bashrc.linux ]; then
    source $DOTFILES_DIR/.bashrc.linux
  fi
fi

# API tokens and private stuff
if [ -f $HOME/.secrets ]; then
  source $HOME/.secrets
fi

if [ -f $HOME/.bashrc.local ]; then
  source $HOME/.bashrc.local
fi

# EOF

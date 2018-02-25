#!/usr/bin/env bash

export LANG="en_US.UTF-8"
export LC_ALL="en_US.UTF-8"

# Bash prompt with Git status
if [ -f $HOME/.bash_prompt ]; then
    source $HOME/.bash_prompt
elif [ -f $HOME/dotfiles/.bash_prompt ]; then
    source $HOME/dotfiles/.bash_prompt
elif [ -f $HOME/.dotfiles/.bash_prompt ]; then
    source $HOME/.dotfiles/.bash_prompt
fi

export EDITOR=vim

# always use vim instead of vi
alias vi=vim

alias ..="cd .."
alias cd..="cd .."
alias ...="cd ../.."

alias g=git
alias gt=git
alias gti=git

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
    if [ -f $HOME/.bashrc.darwin ]; then
        source $HOME/.bashrc.darwin
    elif [ -f $HOME/dotfiles/.bashrc.darwin ]; then
        source $HOME/dotfiles/.bashrc.darwin
    elif [ -f $HOME/.dotfiles/.bashrc.darwin ]; then
        source $HOME/.dotfiles/.bashrc.darwin
    fi
elif [[ $OSTYPE =~ linux ]]; then
    if [ -f $HOME/.bashrc.linux ]; then
        source $HOME/.bashrc.linux
    elif [ -f $HOME/dotfiles/.bashrc.linux ]; then
        source $HOME/dotfiles/.bashrc.linux
    elif [ -f $HOME/.dotfiles/.bashrc.linux ]; then
        source $HOME/.dotfiles/.bashrc.linux
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
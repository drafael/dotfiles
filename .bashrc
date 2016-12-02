#!/usr/bin/env bash

export EDITOR=vim

export PATH=/usr/local/bin:/usr/local/sbin:$PATH
export PATH=$PATH:$HOME/bin

export JAVA_HOME=$(/usr/libexec/java_home)
export PATH=$JAVA_HOME/bin:$PATH

# Erase duplicates in history
export HISTCONTROL=erasedups
# Store 10k history entries
export HISTSIZE=10000
# Append to the history file when exiting instead of overwriting it
shopt -s histappend

if [ -f ~/.bash_prompt ]; then
   source ~/.bash_prompt
fi

if [ -f ~/.bash_aliases ]; then
    source ~/.bash_aliases
fi


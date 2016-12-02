#!/usr/bin/env bash

export EDITOR=vim

export PATH=/usr/local/bin:/usr/local/sbin:$PATH
export PATH=$PATH:$HOME/bin

export JAVA_HOME=$(/usr/libexec/java_home)
export PATH=$JAVA_HOME/bin:$PATH

if [ -f ~/.bash_prompt ]; then
   source ~/.bash_prompt
fi

if [ -f ~/.bash_aliases ]; then
    source ~/.bash_aliases
fi


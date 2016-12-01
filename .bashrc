#!/usr/bin/env bash

export EDITOR=vim

export PATH=/usr/local/bin:/usr/local/sbin:$PATH
export PATH=$PATH:$HOME/bin

export JAVA_HOME=$(/usr/libexec/java_home)
export PATH=$JAVA_HOME/bin:$PATH

if [ -f ~/.bash_prompt ]; then
   source ~/.bash_prompt
fi

alias g="git "
alias gt="git "
alias gti="git"
alias ..="cd .."
alias ...="cd ../.."

# Enable aliases to be sudo’ed
alias sudo='sudo '

# Print each PATH entry on a separate line
alias path='echo -e ${PATH//:/\\n}'

# EOF

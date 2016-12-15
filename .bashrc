#!/usr/bin/env bash

export EDITOR=vim

export LANG="en_US.UTF-8"
export LC_ALL="en_US.UTF-8"

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

alias ..="cd .."
alias cd..="cd .."
alias ...="cd ../.."

alias g="git "
alias gt="git "
alias gti="git "
alias got="git "

alias v="mvim "
alias j="jobs"
alias h="history"

alias brwe=brew
alias cask='brew cask'

# Enable aliases to be sudo’ed
alias sudo='sudo '

# Print each PATH entry on a separate line
alias path='echo -e ${PATH//:/\\n}'

# API tokens and private stuff
if [ -f ~/.secrets ]; then
    source ~/.secrets
fi
if [ -f ~/.bashrc.local ]; then
   source ~/.bashrc.local
fi

#
# bash_prompt
#   (c) Nicolas Gallagher
#   https://github.com/necolas/dotfiles
#
prompt_git() {
    local s=""
    local branchName=""

    # check if the current directory is in a git repository
    if [ $(git rev-parse --is-inside-work-tree &>/dev/null; printf "%s" $?) == 0 ]; then

        # check if the current directory is in .git before running git checks
        if [ "$(git rev-parse --is-inside-git-dir 2> /dev/null)" == "false" ]; then

            # ensure index is up to date
            git update-index --really-refresh  -q &>/dev/null

            # check for uncommitted changes in the index
            if ! $(git diff --quiet --ignore-submodules --cached); then
                s="$s+";
            fi

            # check for unstaged changes
            if ! $(git diff-files --quiet --ignore-submodules --); then
                s="$s!";
            fi

            # check for untracked files
            if [ -n "$(git ls-files --others --exclude-standard)" ]; then
                s="$s?";
            fi

            # check for stashed files 📌
            if $(git rev-parse --verify refs/stash &>/dev/null); then
                s="$s`echo -e "\xf0\x9f\x93\x8c"`";
            fi

        fi

        # get the short symbolic ref
        # if HEAD isn't a symbolic ref, get the short SHA
        # otherwise, just give up
        branchName="$(git symbolic-ref --quiet --short HEAD 2> /dev/null || \
                      git rev-parse --short HEAD 2> /dev/null || \
                      printf "(unknown)")"

        [ -n "$s" ] && s="$s"

        printf "%s" "$1($branchName)$s"
    else
        return
    fi
}

set_prompts() {
    local black=""
    local blue=""
    local bold=""
    local cyan=""
    local green=""
    local orange=""
    local purple=""
    local red=""
    local reset=""
    local white=""
    local yellow=""

    local hostStyle=""
    local userStyle=""

    if [ -x /usr/bin/tput ] && tput setaf 1 >&/dev/null; then
        tput sgr0 # reset colors

        bold=$(tput bold)
        reset=$(tput sgr0)

        # Solarized colors
        # (https://github.com/altercation/solarized/tree/master/iterm2-colors-solarized#the-values)
        black=$(tput setaf 0)
        blue=$(tput setaf 33)
        cyan=$(tput setaf 37)
        green=$(tput setaf 64)
        orange=$(tput setaf 166)
        purple=$(tput setaf 125)
        red=$(tput setaf 124)
        white=$(tput setaf 15)
        yellow=$(tput setaf 136)
    else
        bold=""
        reset="\e[0m"

        black="\e[1;30m"
        blue="\e[1;34m"
        cyan="\e[1;36m"
        green="\e[1;32m"
        orange="\e[1;33m"
        purple="\e[1;35m"
        red="\e[1;31m"
        white="\e[1;37m"
        yellow="\e[1;33m"
    fi

    # build the prompt

    # logged in as root
    if [[ "$USER" == "root" ]]; then
        userStyle="\[$bold$red\]"
    else
        userStyle="\[$green\]"
    fi

    # connected via ssh
    if [[ "$SSH_TTY" ]]; then
        hostStyle="\[$bold$red\]"
    else
        hostStyle="\[$green\]"
    fi

    # set the terminal title to the current working directory
    PS1="\[\033]0;\w\007\]"

    PS1+="\[$userStyle\]\u" # username
    PS1+="\[$reset$green\]@"
    PS1+="\[$hostStyle\]\h" # host
    PS1+="\[$reset$white\] "
    PS1+="\[$reset$yellow\]\w" # working directory
    PS1+="\$(prompt_git \" \")" # git repository details
    PS1+="\n\[$reset\]\$ \[$reset\]" # $ (and reset color)

    export PS1
}

set_prompts
unset set_prompts

# EOF

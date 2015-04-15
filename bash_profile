
# Show Git branch in prompt
parse_git_branch() {
    git branch 2> /dev/null | sed -e '/^[^*]/d' -e 's/* \(.*\)/ (\1)/'
}
# username@hostname path (git branch)
export PS1="\033[32m\]\u@\h \[\033[33m\w\$(parse_git_branch)\033[0m\]\n\$ "

# username@hostname current_dir (git branch)
#export PS1="\033[32m\]\u@\h \[\033[33m\W\$(parse_git_branch)\033[0m\] \$ "

# username@hostname current_dir (git branch)
#export PS1="\u@\h \[\033[33m\W\$(parse_git_branch)\033[0m\] \$ "

# Default editor
export EDITOR=vim

# PATH modifications
export PATH="/usr/local/bin:$PATH"
export PATH=$PATH:$HOME/bin

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

export EDITOR=vim

export HOMEBREW_CASK_OPTS="--appdir=/Applications"

export PATH=/usr/local/bin:/usr/local/sbin:$PATH
export PATH=$PATH:$HOME/bin

export JAVA_HOME=$(/usr/libexec/java_home)
export PATH=$JAVA_HOME/bin:$PATH

export HADOOP_HOME=/usr/local/Cellar/hadoop/2.7.2
export HADOOP_CONF_DIR=$HADOOP_HOME/libexec/etc/hadoop
export HIVE_HOME=/usr/local/Cellar/hive/1.2.1/libexec
export HCAT_HOME=/usr/local/Cellar/hive/1.2.1/libexec/hcatalog

# eval "$(chef shell-init bash)"


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

export HADOOP_HOME=/usr/local/opt/hadoop/libexec
export HADOOP_CONF_DIR=$HADOOP_HOME/etc/hadoop
export HADOOP_PREFIX=$HADOOP_HOME
export PIG_HOME=/usr/local/opt/pig/libexec
export HIVE_HOME=/usr/local/opt/hive/libexec
export HCAT_HOME=/usr/local/opt/hive/libexec/hcatalog
export SPARK_HOME=/usr/local/opt/apache-spark/libexec

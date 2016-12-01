
export EDITOR=vim

export PATH=/usr/local/bin:/usr/local/sbin:$PATH
export PATH=$PATH:$HOME/bin

export JAVA_HOME=$(/usr/libexec/java_home)
export PATH=$JAVA_HOME/bin:$PATH

if [ -f ~/.bash_prompt ]; then
   source ~/.bash_prompt
fi

export HADOOP_HOME=/usr/local/opt/hadoop/libexec
export HADOOP_CONF_DIR=$HADOOP_HOME/etc/hadoop
export HADOOP_PREFIX=$HADOOP_HOME
export PIG_HOME=/usr/local/opt/pig/libexec
export HIVE_HOME=/usr/local/opt/hive/libexec
export HCAT_HOME=/usr/local/opt/hive/libexec/hcatalog
export SPARK_HOME=/usr/local/opt/apache-spark/libexec

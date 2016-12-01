
export EDITOR=vim

export PATH=/usr/local/bin:/usr/local/sbin:$PATH
export PATH=$PATH:$HOME/bin

export JAVA_HOME=$(/usr/libexec/java_home)
export PATH=$JAVA_HOME/bin:$PATH

if [ -f ~/.bash_prompt ]; then
   source ~/.bash_prompt
fi

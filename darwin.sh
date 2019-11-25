
# Java
if [ -x "$(command -v java)" ]; then
  # export JAVA_HOME=$(/usr/libexec/java_home -v 1.8)
  export JAVA_HOME=$(/usr/libexec/java_home -v 11)
  export PATH=$JAVA_HOME/bin:$PATH
fi

# Groovy
export GROOVY_HOME=/usr/local/opt/groovy/libexec


# Java
if [ -x "$(command -v java)" ]; then
  export JAVA_HOME=$(/usr/libexec/java_home -v 11)
  export PATH=$JAVA_HOME/bin:$PATH
fi

# Groovy
export GROOVY_HOME=/usr/local/opt/groovy/libexec


# Add Postgres.app binaries to path
export PATH="$PATH:/Applications/Postgres.app/Contents/Versions/latest/bin"

# Add mongoDB.app binaries to path
export PATH="$PATH:/Applications/MongoDB.app/Contents/Resources/Vendor/mongodb/bin"

# Add Redis.app binaries to path
export PATH="$PATH:/Applications/Redis.app/Contents/Resources/Vendor/redis/bin"

# Add RabbitMQ.app binaries to path
export PATH="$PATH:/Applications/RabbitMQ.app/Contents/Resources/Vendor/rabbitmq/sbin"

# Prefer the workstation JDK installed by bootstrap/bootstrap.sh.
if [ -x /usr/libexec/java_home ] && /usr/libexec/java_home -v 25 >/dev/null 2>&1; then
  export JAVA_HOME=$(/usr/libexec/java_home -v 25)
  case ":$PATH:" in
    *":$JAVA_HOME/bin:"*) ;;
    *) export PATH="$JAVA_HOME/bin:$PATH" ;;
  esac
fi

# Use Colima only when its Docker socket exists. Otherwise preserve Docker's
# selected context, including Docker Desktop.
if [ -S "$HOME/.colima/default/docker.sock" ]; then
  export TESTCONTAINERS_DOCKER_SOCKET_OVERRIDE=/var/run/docker.sock
  export DOCKER_HOST="unix://${HOME}/.colima/default/docker.sock"
fi

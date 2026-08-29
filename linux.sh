# Prefer the workstation JDK installed by bootstrap/bootstrap.sh. Do not
# override TERM: tmux needs each terminal's native capability identifier.
for java_home in /usr/lib/jvm/java-25-openjdk /usr/lib/jvm/java-25-openjdk-*
do
  if [ -x "$java_home/bin/java" ]; then
    export JAVA_HOME="$java_home"
    case ":$PATH:" in
      *":$JAVA_HOME/bin:"*) ;;
      *) export PATH="$JAVA_HOME/bin:$PATH" ;;
    esac
    break
  fi
done
unset java_home

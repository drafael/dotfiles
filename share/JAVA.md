# Java development environment

Bootstrap installs JDK 25 everywhere:

| Platform | JDK | Build tools |
| --- | --- | --- |
| macOS | Homebrew `openjdk@25` | Maven and Gradle |
| Ubuntu | `openjdk-25-jdk` | Maven; Gradle wrapper only |
| Arch | `jdk25-openjdk` | Maven and Gradle |
| Omarchy | `jdk25-openjdk` through Omarchy | Maven and Gradle |

`JAVA_HOME` and `PATH` select JDK 25 in new shells. Verify the environment with:

```sh
java -version
javac -version
mvn -version
gradle --version  # not installed globally on Ubuntu
```

Prefer a repository's `./mvnw` or `./gradlew` wrapper when it exists. Ubuntu intentionally omits its outdated global Gradle package. Neovim installs JDTLS through Mason and includes Lombok support. IntelliJ IDEA is an optional install documented in [INSTALL.md](INSTALL.md).

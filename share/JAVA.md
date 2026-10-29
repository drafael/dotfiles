# Java development environment

Bootstrap installs JDK 25 everywhere:

| Platform | JDK | Build tools |
| --- | --- | --- |
| macOS | Homebrew `openjdk@25` | Maven and Gradle |
| Ubuntu | `openjdk-25-jdk` | Maven; Gradle wrapper only |
| Fedora | `java-25-openjdk-devel` | Maven; Gradle wrapper only |
| Arch | `jdk25-openjdk` | Maven and Gradle |
| Omarchy | `jdk25-openjdk` through Omarchy | Maven and Gradle |

## Configure `JAVA_HOME` automatically

After running `./bootstrap/java.sh` and linking the shell configuration with `./bootstrap/link-dotfiles.sh`, open a new terminal. The configured shell already prefers JDK 25:

- On macOS, `.zshrc` sources [`darwin.sh`](../darwin.sh), which discovers a registered JDK through `/usr/libexec/java_home`.
- On Linux, `.zshrc` or Omarchy's managed `.bashrc` block sources [`linux.sh`](../linux.sh), which checks `/usr/lib/jvm/java-25-openjdk` and `/usr/lib/jvm/java-25-openjdk-*`.

These scripts export `JAVA_HOME` and prepend its `bin` directory to `PATH` when they find Java. Running the bootstrap script alone cannot change the environment of the shell that launched it. Verify the selected version below rather than assuming that installing a JDK selected it everywhere.

The manual setup and optional overrides below do not require another version manager. With these dotfiles, put overrides in `~/.zshrc.local`, which loads after the platform settings. On Omarchy, put them after the managed dotfiles block in `~/.bashrc`. Without these dotfiles, use `~/.zshrc` for Zsh, `~/.bashrc` for interactive Bash on Linux, or `~/.bash_profile` for a Bash login shell on macOS.

### macOS: discover a registered JDK

`bootstrap/java.sh` already installs and registers JDK 25. For a manual installation:

```sh
brew install openjdk@25
```

Homebrew's JDK must be registered for macOS's Java tools to discover it. Only create the following link if `/Library/Java/JavaVirtualMachines/openjdk-25.jdk` does not already exist; inspect an existing file or symlink instead of overwriting it:

```sh
sudo mkdir -p /Library/Java/JavaVirtualMachines
sudo ln -s "$(brew --prefix openjdk@25)/libexec/openjdk.jdk" \
  /Library/Java/JavaVirtualMachines/openjdk-25.jdk
```

List registered JDKs and check that version 25 can be selected:

```sh
/usr/libexec/java_home -V
/usr/libexec/java_home -F -v 25
```

For automatic selection in new shells, add this to the appropriate startup file above. The repository already has similar logic in `darwin.sh`; add a local override only if you need to change its selection:

```sh
if [ -x /usr/libexec/java_home ] && /usr/libexec/java_home -F -v 25 >/dev/null 2>&1; then
  export JAVA_HOME="$(/usr/libexec/java_home -F -v 25)"
  export PATH="$JAVA_HOME/bin:$PATH"
fi
```

This resolves the installed JDK at shell startup instead of hard-coding a Homebrew prefix or patch-version directory. `-F` makes the lookup fail when version 25 is absent; without it, `java_home` can fall back to another JDK. To select another installed major version, replace both occurrences of `25` in the shell snippet. See [Homebrew's registration instructions](https://formulae.brew.sh/formula/openjdk@25) and `man java_home`.

### Ubuntu and Fedora: optionally follow the system-selected JDK

The repository's default remains JDK 25. If you want new shells to follow the distribution's selected JDK instead, first select its development tools. These commands change system defaults; skip this step if you want to keep them unchanged.

On Ubuntu, list registered JDKs:

```sh
update-java-alternatives --list
```

Run `sudo update-java-alternatives --set NAME`, replacing `NAME` with the exact JDK name from that list. This selects the registered installation's tools together. See the [`update-java-alternatives` manual](https://manpages.debian.org/trixie/java-common/update-java-alternatives.8.en.html).

On Fedora, select the runtime and compiler separately, choosing the same JDK version for both:

```sh
sudo alternatives --config java
sudo alternatives --config javac
```

These selectors do not export `JAVA_HOME`. For a distribution-packaged JDK, add the following shell override to derive its home from the resolved compiler path:

```sh
if [ -x /usr/bin/javac ]; then
  java_home=$(dirname "$(dirname "$(readlink -f /usr/bin/javac)")")
  if [ -x "$java_home/bin/java" ]; then
    export JAVA_HOME="$java_home"
    export PATH="$JAVA_HOME/bin:$PATH"
  fi
fi
unset java_home
```

Using `/usr/bin/javac` avoids choosing the repository's JDK 25 merely because it is already first on `PATH`. It also avoids hard-coding Ubuntu's architecture suffix or Fedora's installed JDK directory. This is a best-effort method for distribution packages, not version-manager shims or arbitrary tarball installations. See [Fedora's Java documentation](https://docs.fedoraproject.org/en-US/quick-docs/installing-java/).

### Arch and Omarchy: optionally follow `archlinux-java`

To follow Arch's selected JDK rather than the repository's fixed JDK 25 preference, list installed environments and choose a JDK from that list:

```sh
archlinux-java status
```

For example, if `java-25-openjdk` is listed, select it with `sudo archlinux-java set java-25-openjdk`. This changes the system default. Do not edit `/usr/lib/jvm/default` directly; `archlinux-java` manages that link.

Add this override to the appropriate shell startup file to follow the managed link:

```sh
if [ -x /usr/lib/jvm/default/bin/javac ]; then
  export JAVA_HOME=/usr/lib/jvm/default
  export PATH="$JAVA_HOME/bin:$PATH"
fi
```

Arch does not normally require `JAVA_HOME`, but Java development tools can require it. See [ArchWiki's Java guide](https://wiki.archlinux.org/title/Java).

## Verify the selected JDK

Open a new terminal after changing a startup file, then run:

```sh
printf 'JAVA_HOME=%s\n' "${JAVA_HOME:-unset}"
command -v java
command -v javac
java -version
javac -version
mvn -version
```

`JAVA_HOME` must point to the JDK root, not its `bin` directory. Check that `$JAVA_HOME/bin/javac` exists and that Java, the compiler, and Maven report the intended major version. Unless you added an override, expect version 25. If macOS cannot find it, check registration with `/usr/libexec/java_home -F -v 25`; on Linux, check that the JDK development package from the table is installed.

Shell startup files affect the shell and processes launched from it. IDEs opened from the Dock or a desktop launcher may not inherit these settings; select the project SDK in the IDE separately.

## Build tools and editors

Prefer a repository's `./mvnw` or `./gradlew` wrapper when it exists. Ubuntu and Fedora use project Gradle wrappers instead of installing a global Gradle package. On the other platforms, check the global Gradle installation with `gradle --version`.

Neovim installs JDTLS through Mason and includes Lombok support. IntelliJ IDEA is an optional install documented in [INSTALL.md](INSTALL.md).

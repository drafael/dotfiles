# Workstation dotfiles

A personal terminal and Java development environment for macOS, Ubuntu, Arch Linux, and Omarchy 4. The bootstrap installs the core tools, backs up conflicting files, and links this repository's configuration.

## Supported platforms

| Platform | Shell | Terminal | Coding agents |
| --- | --- | --- | --- |
| macOS | Zsh | Ghostty | Official installers |
| Ubuntu 24.04+ | Zsh | Kitty | Official installers |
| Arch Linux | Zsh | Ghostty | Official installers |
| Omarchy 4 | Bash | Foot | Omarchy lazy launchers |

Omarchy keeps its native shell, terminal, desktop theme integration, package lifecycle, and agent launchers. The bootstrap applies the portable Git, tmux, Neovim, aliases, and environment configuration there.

## Bootstrap a workstation

### 1. Install Git

Use the command for the target platform:

```sh
# macOS
xcode-select --install

# Ubuntu
sudo apt update && sudo apt install git

# Arch
sudo pacman -S git
```

Omarchy already includes Git.

### 2. Clone and run bootstrap

```sh
git clone https://github.com/drafael/dotfiles.git ~/.dotfiles
cd ~/.dotfiles
./bootstrap/bootstrap.sh
```

On macOS, the script installs Homebrew when needed and uses its unversioned `node` and `bun` formulas for the current releases by default. To manage both runtimes with `mise` instead, run:

```sh
./bootstrap/bootstrap.sh --javascript-runtime-manager=mise
```

Package installation and login-shell changes may request your password. If a package or download fails, fix the reported problem and run the same command again.

The bootstrap installs:

- Git, Git LFS, GitHub CLI (`gh`), GitLab CLI (`glab`), Starship, tmux, Neovim, fzf, fd, zoxide, and ripgrep
- Node.js and Bun runtimes, plus TypeScript, TypeScript Language Server, and `tsx`
- Ghostty on macOS and Arch, or Kitty on Ubuntu
- JDK 25 and the platform-appropriate Java build tools
- Claude Code, Codex, OpenCode, and Pi outside Omarchy

It links Git, tmux, and Neovim configuration on every platform. Zsh platforms also receive `.zshrc` and terminal configuration. On Omarchy, the script preserves Bash and Foot and adds a small source block to `~/.bashrc`.

When a destination already exists, the script moves it to:

```text
~/.dotfiles-backups/YYYYMMDD-HHMMSS/
```

A numeric suffix is added if two runs start during the same second.

To link every top-level entry from this repository's `.config` directory instead of the platform-specific selection, run the separate script manually:

```sh
~/.dotfiles/bootstrap/link-config.sh
```

It uses `${XDG_CONFIG_HOME:-$HOME/.config}`, leaves correct symlinks unchanged, and backs up conflicting destinations under `~/.dotfiles-backups/`.

### 3. Start the configured shell

On macOS, Ubuntu, or Arch:

```sh
exec zsh
```

On Omarchy, open a new terminal.

## Finish setup

### Configure Git identity

Create `~/.gitconfig.local`; the tracked Git configuration includes it automatically:

```ini
[user]
    name = YOUR NAME
    email = YOUR EMAIL
```

### Authenticate Git hosts

This Git configuration pushes to GitHub over SSH. Authenticate the hosts you use:

```sh
gh auth login --git-protocol ssh
glab auth login --hostname gitlab.com --git-protocol ssh
# Self-managed GitLab:
glab auth login --hostname gitlab.example.com --git-protocol ssh
```

See [share/GIT.md](share/GIT.md) for verification, SSH keys, personal access tokens, separate API or SSH hosts, and credential storage.

### Authenticate coding agents

Start each agent and follow its authentication flow:

```sh
claude
codex
opencode
pi
```

Omarchy installs these agents through its existing `mise` launchers the first time each command runs. Other platforms use the agents' official installers during bootstrap.

The optional shared agent configuration lives in [drafael/coding-harness](https://github.com/drafael/coding-harness).

## Java development environment

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

Prefer a repository's `./mvnw` or `./gradlew` wrapper when it exists. Ubuntu intentionally omits its outdated global Gradle package. Neovim installs JDTLS through Mason and includes Lombok support. IntelliJ IDEA is an optional install documented in [share/INSTALL.md](share/INSTALL.md).

## JavaScript runtimes and TypeScript

On macOS, bootstrap installs the current Node.js and Bun releases with Homebrew's unversioned `node` and `bun` formulas by default. Pass `--javascript-runtime-manager=mise` to install the latest supported Node.js LTS release and latest Bun release through `mise` instead. Linux platforms use `mise`. Bootstrap also installs the TypeScript compiler, TypeScript Language Server, and `tsx`. Verify them with:

```sh
node --version
npm --version
bun --version
tsc --version
typescript-language-server --version
tsx --version
```

Keep ESLint, Prettier, test runners, and framework tooling in each project so their versions remain reproducible. Follow the package manager and lockfile already used by the project.

## Local customization

Use untracked local files for machine-specific settings:

- `~/.zshrc.local` for Zsh exports and commands
- `~/.gitconfig.local` for Git identity and credentials
- `~/.bashrc` for additional Omarchy Bash settings

The tmux project launcher scans `~/code` and `~/src` by default. Override its roots before starting tmux:

```sh
export TMUX_PROJECT_DIRS="$HOME/code:$HOME/src"
```

Add this export to `~/.zshrc.local`, or to `~/.bashrc` on Omarchy.

## Daily commands

Tmux uses `Ctrl-Space` as its prefix.

| Command or binding | Action |
| --- | --- |
| `tc NAME` | Create a tmux session |
| `ta NAME` | Attach to a tmux session |
| `tl` | List tmux sessions |
| `tk NAME` | Kill a tmux session |
| `prefix`, `\|` / `-` | Split right or below |
| `Ctrl-h/j/k/l` | Navigate Neovim splits and tmux panes |
| `Ctrl-Shift-h/j/k/l` | Resize Neovim splits or tmux panes |
| `prefix`, `f` | Search tmux objects with fzf |
| `prefix`, `p` | Open the project launcher |
| `prefix`, `T` | Toggle the dark and light themes |
| `prefix`, `S` | Move or hide the status line |
| `prefix`, `r` | Reload tmux configuration |

See [share/TMUX.md](share/TMUX.md) for every binding, clipboard behavior, project discovery, and terminal troubleshooting.

## Update or recover

Update the repository and reapply the setup with:

```sh
cd ~/.dotfiles
git pull --ff-only
./bootstrap/bootstrap.sh
```

The script is idempotent and leaves correct symlinks unchanged. Inspect `~/.dotfiles-backups/` to restore a configuration that bootstrap replaced.

On Omarchy, run `omarchy update` for system updates. Do not use `pacman -Syu` directly. If `omarchy reinstall configs` resets personal links, rerun the bootstrap.

## Troubleshooting

- Restart Ghostty or Kitty after terminal configuration changes.
- Run `tmux -V`; this configuration requires tmux 3.3 or newer.
- Run `infocmp tmux-256color` if colors or modified keys are wrong.
- On Ubuntu, rerun bootstrap if the verified Neovim download was interrupted.
- Review [share/TMUX.md](share/TMUX.md) for terminfo and remote-host instructions.
- Review [share/INSTALL.md](share/INSTALL.md) for optional editors, containers, terminals, and CLI tools.

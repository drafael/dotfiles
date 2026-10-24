# Workstation dotfiles

A personal terminal and Java development environment for macOS, Ubuntu, Fedora Workstation, Arch Linux, and Omarchy 4. The bootstrap scripts install the core tools, back up conflicting files, and link this repository's configuration.

See [Supported platforms](share/PLATFORMS.md) for the operating systems, shells, terminals, and coding-agent installation methods covered by the bootstrap scripts.

## Bootstrap scripts

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

### 2. Clone and run the bootstrap scripts

```sh
git clone https://github.com/drafael/dotfiles.git ~/.dotfiles
cd ~/.dotfiles
./bootstrap/bootstrap.sh
```

On macOS, the script installs Homebrew when needed and uses its unversioned `node` and `bun` formulas for the current releases by default. To manage both runtimes with `mise` instead, run:

```sh
./bootstrap/bootstrap.sh --javascript-runtime-manager=mise
```

Package installation and login-shell changes may request your password. Each script installs missing tools without upgrading tools that are already present. If a package or download fails, fix the reported problem and run the same command again.

The default bootstrap scripts install:

- Git, Git LFS, GitHub CLI (`gh`), GitLab CLI (`glab`), Starship, tmux, Neovim, fzf, fd, zoxide, and ripgrep
- btop, htop, LazyGit, Tig, Midnight Commander, Yazi, Midday Commander (`mdc`), jq, tree, and wget
- Yazi preview support through FFmpeg, 7-Zip, Poppler, `resvg`, and ImageMagick where platform packages are available
- Node.js and Bun runtimes, plus TypeScript, TypeScript Language Server, and `tsx`
- Ghostty on macOS and Arch, or Kitty on Ubuntu and Fedora
- Fira Code, JetBrains Mono, Cascadia Code, Source Code Pro, Hack, FiraCode Nerd Font, and the regular and monospace symbols-only Nerd Fonts
- [JDK 25 and the platform-appropriate Java build tools](share/JAVA.md)
- 1Password desktop app and CLI (`op`); pass `--onepassword-cli-only` on headless Linux
- Claude Code, Codex, OpenCode, and Pi outside Omarchy
- Herdr agent multiplexer through Homebrew on macOS or its official installer on Linux
- RevDiff plus its Claude Code, Codex, OpenCode, and Pi integrations, including automatic plan review where supported

The bootstrap scripts can be run independently by category:

| Script | Responsibility |
| --- | --- |
| `cli-tools.sh` | Git clients, terminal utilities, file managers, Yazi preview support, and command-line prerequisites |
| `javascript.sh` | Node.js, Bun, TypeScript, TypeScript Language Server, and `tsx` |
| `java.sh` | JDK 25, Maven, and Gradle where supported |
| `fonts.sh` | Programming fonts and Nerd Font symbol families |
| `terminal-tools.sh` | Neovim and the platform terminal |
| `coding-agents.sh` | Claude Code, Codex, OpenCode, Pi, Herdr, RevDiff integrations, and shared harness configuration |
| `link-dotfiles.sh` | Repository configuration links and shell integration |
| `verify.sh` | Read-only installed-version summary |
| `containers.sh` | Optional Docker- or Podman-based runtime and local Kubernetes tools |
| `gui-editors.sh` | Optional IntelliJ IDEA, VS Code, Cursor, and Zed installation |
| `1password.sh` | 1Password desktop app and CLI (`op`); `--cli-only` for headless Linux |

Run a category from the repository root when only that part of the workstation needs provisioning, for example:

```sh
./bootstrap/java.sh
./bootstrap/link-dotfiles.sh
```

The [CI workflow for the bootstrap scripts](.github/workflows/bootstrap.yml) checks POSIX shell syntax and non-installing `--help` paths on Ubuntu and macOS, runs ShellCheck on Ubuntu, and checks Fedora detection and package names in a Fedora container. It does not run a privileged workstation install or exercise Arch and Omarchy at runtime.

`containers.sh` and `gui-editors.sh` are optional and are not called by the default bootstrap scripts. The default bootstrap scripts include 1Password; on headless Linux, use `./bootstrap/bootstrap.sh --onepassword-cli-only`. Arch and Omarchy ARM64 use signature-verified vendor releases; Fedora uses 1Password's signed RPM repository, and Omarchy x86-64 uses its signed repository packages. See [share/INSTALL.md](share/INSTALL.md#1password) for installation and update requirements. Install the Docker-compatible container stack, or select Podman explicitly:

```sh
./bootstrap/containers.sh
./bootstrap/containers.sh --runtime=podman
```

The container script installs runtime packages and command-line tools but does not deliberately start runtimes or services, grant Docker group access, or create Kubernetes clusters. Ubuntu installs Yazi from its official APT repository; unavailable optional preview dependencies such as `resvg` produce a warning instead of failing the bootstrap scripts.

`link-dotfiles.sh` links each portable top-level entry under `.config` into `${XDG_CONFIG_HOME:-$HOME/.config}`. Ghostty and Kitty are handled separately so each platform receives the correct terminal configuration; Omarchy retains its terminal configuration. Root Git files remain explicit, Zsh platforms receive `.zshrc`, and Omarchy receives a managed source block in `~/.bashrc`.

When a destination already exists, the script moves it to:

```text
~/.dotfiles-backups/YYYYMMDD-HHMMSS/
```

A numeric suffix is added if two runs start during the same second. Correct symlinks remain unchanged, and stale links are not removed automatically. Most configuration directories are linked wholesale, so application changes within them write directly into this repository.

### 3. Start the configured shell

On macOS, Ubuntu, Fedora, or Arch:

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

The bootstrap scripts set up Claude Code, Codex, OpenCode, and Pi, link the shared coding harness, and configure RevDiff and Herdr integrations. Authenticate each agent after setup; GitHub Copilot CLI installation remains separate. See the [coding-agent setup guide](share/CODING-AGENTS.md) for installation, authentication, integration, and recovery details.

## JavaScript runtimes and TypeScript

On macOS, the bootstrap scripts install the current Node.js and Bun releases with Homebrew's unversioned `node` and `bun` formulas by default. Pass `--javascript-runtime-manager=mise` to install the latest supported Node.js LTS release and latest Bun release through `mise` instead. Linux platforms use `mise`. The bootstrap scripts also install the TypeScript compiler, TypeScript Language Server, and `tsx`. Verify them with:

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

The bootstrap scripts remain install-only: rerunning them does not upgrade existing tools. They are idempotent and leave correct symlinks unchanged. Inspect `~/.dotfiles-backups/` to restore a configuration that the bootstrap scripts replaced.

To update installed tools separately, run as your normal user:

```sh
./update.sh                    # Tools managed by bootstrap scripts, including installed optional apps
./update.sh --scope=all        # All packages in supported managers and recognized tools
```

The updater requires `python3` and `jq`. It disables Homebrew confirmations and sudo, does not force apps to quit, and reports privileged or unsupported updates as skipped. It does not install missing tools, change installation methods, or update project dependencies. Package-manager dependencies and dependants can still change. Exit statuses are `0` for completion, `1` for update failures, `2` for skipped targets without failures, and `3` for setup or usage errors. See [Unattended tool updates](share/INSTALL.md#unattended-tool-updates) for supported update paths and limits.

On Omarchy, run `omarchy update` for system updates. Do not use `pacman -Syu` directly. If `omarchy reinstall configs` resets personal links, rerun the bootstrap scripts.

## Troubleshooting

- Restart Ghostty or Kitty after terminal configuration changes.
- Run `tmux -V`; this configuration requires tmux 3.3 or newer.
- Run `infocmp tmux-256color` if colors or modified keys are wrong.
- On Ubuntu, rerun the bootstrap scripts if the verified Neovim download was interrupted.
- Review [share/TMUX.md](share/TMUX.md) for terminfo and remote-host instructions.
- Review [share/INSTALL.md](share/INSTALL.md) for optional editors, containers, terminals, and CLI tools.

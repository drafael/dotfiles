# Workstation dotfiles

A personal terminal and Java development environment for macOS, Ubuntu, Arch Linux, and Omarchy 4. The bootstrap installs the core tools, backs up conflicting files, and links this repository's configuration.

See [Supported platforms](share/PLATFORMS.md) for the operating systems, shells, terminals, and coding-agent installation methods covered by the bootstrap.

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

Package installation and login-shell changes may request your password. Each script installs missing tools without upgrading tools that are already present. If a package or download fails, fix the reported problem and run the same command again.

The default bootstrap installs:

- Git, Git LFS, GitHub CLI (`gh`), GitLab CLI (`glab`), Starship, tmux, Neovim, fzf, fd, zoxide, and ripgrep
- btop, htop, LazyGit, Tig, Midnight Commander, Yazi, Midday Commander (`mdc`), jq, tree, and wget
- Yazi preview support through FFmpeg, 7-Zip, Poppler, `resvg`, and ImageMagick where platform packages are available
- Node.js and Bun runtimes, plus TypeScript, TypeScript Language Server, and `tsx`
- Ghostty on macOS and Arch, or Kitty on Ubuntu
- JDK 25 and the platform-appropriate Java build tools
- Claude Code, Codex, OpenCode, and Pi outside Omarchy
- RevDiff plus its Claude Code, Codex, OpenCode, and Pi integrations, including automatic plan review where supported

The bootstrap is composed of independently runnable category scripts:

| Script | Responsibility |
| --- | --- |
| `cli-tools.sh` | Git clients, terminal utilities, file managers, Yazi preview support, and command-line prerequisites |
| `javascript.sh` | Node.js, Bun, TypeScript, TypeScript Language Server, and `tsx` |
| `java.sh` | JDK 25, Maven, and Gradle where supported |
| `terminal-tools.sh` | Neovim and the platform terminal |
| `coding-agents.sh` | Claude Code, Codex, OpenCode, Pi, RevDiff integrations, and shared harness configuration |
| `link-dotfiles.sh` | Repository configuration links and shell integration |
| `verify.sh` | Read-only installed-version summary |
| `gui-editors.sh` | Optional IntelliJ IDEA, VS Code, Cursor, and Zed installation |

Run a category from the repository root when only that part of the workstation needs provisioning, for example:

```sh
./bootstrap/java.sh
./bootstrap/link-dotfiles.sh
```

`gui-editors.sh` is optional and is not called by the default bootstrap. Ubuntu installs Yazi from its official APT repository; unavailable optional preview dependencies such as `resvg` produce a warning instead of failing the bootstrap.

`link-dotfiles.sh` links each portable top-level entry under `.config` into `${XDG_CONFIG_HOME:-$HOME/.config}`. Ghostty and Kitty are handled separately so each platform receives the correct terminal configuration; Omarchy retains its terminal configuration. Root Git files remain explicit, Zsh platforms receive `.zshrc`, and Omarchy receives a managed source block in `~/.bashrc`.

When a destination already exists, the script moves it to:

```text
~/.dotfiles-backups/YYYYMMDD-HHMMSS/
```

A numeric suffix is added if two runs start during the same second. Correct symlinks remain unchanged, and stale links are not removed automatically. Most configuration directories are linked wholesale, so application changes within them write directly into this repository.

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

Bootstrap also installs [RevDiff](https://github.com/umputun/revdiff). macOS uses its Homebrew formula; Linux installs the checksummed release archive in `~/.local/bin`. Claude Code and Codex receive the `revdiff` and `revdiff-planning` marketplace plugins, Pi receives the RevDiff package, and OpenCode receives its command, tool, and plan-review plugin. Start a new agent session after bootstrap; in Codex, open `/hooks` and trust the RevDiff planning hook before using automatic Plan-mode review.

Bootstrap clones [drafael/coding-harness](https://github.com/drafael/coding-harness) to `~/code/harness`, preferring SSH and warning before falling back to HTTPS. Existing HTTPS or SSH checkouts are left at their current revision.

The bootstrap links the harness skills into `~/.agents/skills` and `~/.claude/skills`. It also links the shared Pi themes, prompts, extensions, and `AGENTS.md` under `~/.pi/agent`, creates `~/.agents/AGENTS.md`, and links `CLAUDE.md` to `~/.claude/CLAUDE.md`. Conflicting paths are backed up under `~/.dotfiles-backups/` before replacement.

See [Java development environment](share/JAVA.md) for the JDK and build tools installed on each platform, environment setup, and verification commands.

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

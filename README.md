# Workstation dotfiles

A personal terminal and Java development environment for macOS, Ubuntu, Fedora Workstation, Arch Linux, and Omarchy 4. The bootstrap installs the core tools, backs up conflicting files, and links this repository's configuration.

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
- Ghostty on macOS and Arch, or Kitty on Ubuntu and Fedora
- Fira Code, JetBrains Mono, Cascadia Code, Source Code Pro, Hack, FiraCode Nerd Font, and the regular and monospace symbols-only Nerd Fonts
- JDK 25 and the platform-appropriate Java build tools
- 1Password desktop app and CLI (`op`); pass `--onepassword-cli-only` on headless Linux
- Claude Code, Codex, OpenCode, and Pi outside Omarchy
- Herdr agent multiplexer through Homebrew on macOS or its official installer on Linux
- RevDiff plus its Claude Code, Codex, OpenCode, and Pi integrations, including automatic plan review where supported

The bootstrap is composed of independently runnable category scripts:

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

The [bootstrap CI workflow](.github/workflows/bootstrap.yml) checks POSIX shell syntax and non-installing `--help` paths on Ubuntu and macOS, runs ShellCheck on Ubuntu, and checks Fedora detection and package names in a Fedora container. It does not run a privileged workstation install or exercise Arch and Omarchy at runtime.

`containers.sh` and `gui-editors.sh` are optional and are not called by the default bootstrap. The default bootstrap includes 1Password; on headless Linux, use `./bootstrap/bootstrap.sh --onepassword-cli-only`. Arch and Omarchy ARM64 use signature-verified vendor releases; Fedora uses 1Password's signed RPM repository, and Omarchy x86-64 uses its signed repository packages. See [share/INSTALL.md](share/INSTALL.md#1password) for installation and update requirements. Install the Docker-compatible container stack, or select Podman explicitly:

```sh
./bootstrap/containers.sh
./bootstrap/containers.sh --runtime=podman
```

The container script installs runtime packages and command-line tools but does not deliberately start runtimes or services, grant Docker group access, or create Kubernetes clusters. Ubuntu installs Yazi from its official APT repository; unavailable optional preview dependencies such as `resvg` produce a warning instead of failing the bootstrap.

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

Start each agent and follow its authentication flow:

```sh
claude
codex
opencode
pi
```

Omarchy installs these agents through its existing `mise` launchers the first time each command runs. Other platforms use the agents' official installers during bootstrap.

Bootstrap also installs [Herdr](https://herdr.dev/docs/install/): the Homebrew formula `herdr` on macOS, or the official checksum-verifying installer on Ubuntu, Fedora, Arch, and Omarchy. The Linux installer selects the x86-64 or ARM64 release and defaults to `~/.local/bin/herdr`; Omarchy keeps its existing agent launchers. Existing Herdr commands on `PATH` are left untouched, regardless of installation method. Start it manually with `herdr`; bootstrap installs its Pi, Codex, and Claude Code integrations but does not launch Herdr, install integrations for other agents, or replace tmux.

Update Homebrew installations with `./update.sh` or `brew upgrade herdr`, not `herdr update`. Direct Linux installations use `herdr update` separately; `./update.sh` does not update those installations. Intel Macs may require a source build with Rust and Zig when no Homebrew bottle is available.

For a missing Pi installation, bootstrap uses the [pi.dev installer](https://pi.dev/docs/latest/quickstart#1-install-pi), which pins all dependencies; update it later with `pi update`. The installer may prompt to start Pi immediately: choose **n** to let bootstrap continue. Existing Pi installations are left untouched. To migrate an existing npm installation to the managed installer, run `curl -fsSL https://pi.dev/install.sh | sh` separately and confirm migration; the installer verifies the managed release before removing the npm installation. Direct npm installation remains supported upstream but no longer pins transitive dependencies.

Bootstrap also installs [RevDiff](https://github.com/umputun/revdiff). macOS uses its Homebrew formula; Linux installs the checksummed release archive in `~/.local/bin`. Claude Code and Codex receive the `revdiff` and `revdiff-planning` marketplace plugins. Pi receives the RevDiff package plus the [pi-subagents](https://github.com/nicobailon/pi-subagents), [pi-web-access](https://github.com/nicobailon/pi-web-access), [pi-intercom](https://github.com/nicobailon/pi-intercom), and [pi-voice-stt](https://github.com/cgarrot/pi-voice-stt) npm packages. OpenCode receives the RevDiff command, tool, and plan-review plugin. Start a new agent session after bootstrap; in Codex, open `/hooks` and trust the RevDiff planning hook before using automatic Plan-mode review.

Bootstrap clones [drafael/coding-harness](https://github.com/drafael/coding-harness) to `~/code/harness`, preferring SSH and warning before falling back to HTTPS. Existing HTTPS or SSH checkouts are left at their current revision.

The bootstrap links the harness skills into `~/.agents/skills` and `~/.claude/skills`. It also links the shared Pi themes, prompts, `stt.json`, and `AGENTS.md` under `~/.pi/agent`, creates `~/.agents/AGENTS.md`, and links `CLAUDE.md` to `~/.claude/CLAUDE.md`. These conflicting paths are backed up under `~/.dotfiles-backups/` before replacement.

Pi's `extensions/` stays a real, machine-local directory. Bootstrap links each Git-tracked, direct `.ts` or `.js` harness extension individually; untracked source experiments are not linked. Herdr generates its own regular `herdr-agent-state.ts` there, outside the harness checkout. `PI_CODING_AGENT_DIR` overrides the extension directory and Herdr integration destination; the other harness links keep their existing destinations. Do not also load the linked files through Pi's `settings.extensions` or a local package declaration, which can load them twice.

An existing whole-directory symlink is migrated only if it points to the expected harness directory and contains no extra entries. The old link is backed up without changing its target. Identical regular extension copies are backed up and replaced with file links. Modified files, foreign links, directories at extension filenames, and a versioned `herdr-agent-state.ts` are conflicts: bootstrap stops for manual resolution rather than overwriting them. Unrelated local extensions stay untouched. Backups live outside Pi's discovery directory; their location is printed by bootstrap. After a source rename or removal, broken extension links are reported and left for manual retirement.

After establishing the links, bootstrap runs `herdr integration install pi` only if the integration is missing. Existing regular integration files are preserved. After upgrading Herdr, refresh explicitly with the same command, then restart Pi or run `/reload`. `herdr integration status` reports the integration version; bootstrap does not parse that human-readable output or upgrade integrations automatically. Live status reporting and session resume require Pi to run inside Herdr.

Codex integration setup requires Python 3.11+ (standard-library TOML parsing) and jq on `PATH`; bootstrap checks this prerequisite rather than installing or upgrading Python automatically. It inspects `${CODEX_HOME:-$HOME/.codex}/herdr-agent-state.sh`, `hooks.json`, and `config.toml` before invoking Herdr. A structurally complete integration is left untouched. A missing or recognized partial integration is installed or repaired with `herdr integration install codex`, after backing up existing affected files under `~/.dotfiles-backups/`. Herdr merges its SessionStart registration and enables `[features].hooks`; unrelated settings and hooks are preserved by its native installer.

Malformed configuration, symlinked managed paths, an unrecognized script at Herdr's filename, and explicitly disabled `features.hooks = false` stop Codex setup before native writes. If hooks are disabled intentionally, review that choice before enabling them and rerunning. Bootstrap validates all three artifacts after installation: Herdr's own status can report "current" even when the hook registration is missing. Native installation is not a multi-file transaction; on failure, inspect the reported partial state and backups before retrying. Native uninstall leaves `config.toml` unchanged and is not a rollback substitute. Do not run bootstrap concurrently with other Codex configuration writers. Integration versions are not upgraded automatically; refresh explicitly after Herdr upgrades, as with Pi.

Claude Code integration setup uses the same Python 3.11+ and jq prerequisites. Bootstrap inspects `${CLAUDE_CONFIG_DIR:-$HOME/.claude}/hooks/herdr-agent-state.sh` and `settings.json`. A complete integration is left untouched, including older script versions. Missing or recognized partial installations are backed up and installed or repaired with `herdr integration install claude`. Herdr merges its SessionStart registration while preserving unrelated settings, plugins, and hooks. The generated script and its directory stay machine-local; existing harness skills and instruction links are unchanged, including their destinations when `CLAUDE_CONFIG_DIR` is set.

Claude setup stops before Herdr writes if settings are malformed, `disableAllHooks` is true, managed paths are symlinks, the script is unrecognized, or a registration for that script has a custom command or matcher. Bootstrap preserves Herdr's native `^(startup|resume|clear|compact|fork)$` matcher rather than broadening it. Resolve custom or legacy registrations manually before rerunning; bootstrap will not silently broaden their scope. Installation is validated structurally; Herdr's status alone does not detect missing registration or disabled hooks.

Claude backups are saved under `~/.dotfiles-backups/`, with their location printed. On installation failure, inspect both affected paths and the backups before retrying; bootstrap does not automatically uninstall or restore files. Do not run it concurrently with other Claude settings writers. After upgrading Herdr, refresh explicitly with `herdr integration install claude`; bootstrap does not upgrade complete integrations automatically or restart sessions. Verify activation with a new Claude session inside Herdr. The hook reports session identity; managed or project policies can still prevent execution, and bootstrap does not validate live hook delivery or session resume.

Pi Voice STT uses the harness provider profiles and the plugin's platform capture defaults: `avfoundation` / `:0` on macOS and `pulse` / `default` on Linux (PulseAudio or PipeWire's PulseAudio compatibility service). Microphone capture requires `ffmpeg`, a working input device, and the selected provider's API key (the shared default uses `GROQ_API_KEY`). On Linux, check that `ffmpeg -devices` lists `pulse`; ALSA-only systems can use `capture.inputFormat: "alsa"` and `capture.input: "default"` in a machine-specific config selected with `PI_STT_CONFIG`. Audio-file transcription does not require microphone capture. Bootstrap does not test microphones or configure audio services. If an older harness checkout lacks `stt.json`, bootstrap warns and leaves the local STT config untouched; update the checkout manually and rerun bootstrap.

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

The bootstrap remains install-only: rerunning it does not upgrade existing tools. It is idempotent and leaves correct symlinks unchanged. Inspect `~/.dotfiles-backups/` to restore a configuration that bootstrap replaced.

To update installed tools separately, run as your normal user:

```sh
./update.sh                    # Bootstrap toolset, including installed optional apps
./update.sh --scope=all        # All packages in supported managers and recognized tools
```

The updater requires `python3` and `jq`. It disables Homebrew confirmations and sudo, does not force apps to quit, and reports privileged or unsupported updates as skipped. It does not install missing tools, change installation methods, or update project dependencies. Package-manager dependencies and dependants can still change. Exit statuses are `0` for completion, `1` for update failures, `2` for skipped targets without failures, and `3` for setup or usage errors. See [Unattended tool updates](share/INSTALL.md#unattended-tool-updates) for supported update paths and limits.

On Omarchy, run `omarchy update` for system updates. Do not use `pacman -Syu` directly. If `omarchy reinstall configs` resets personal links, rerun the bootstrap.

## Troubleshooting

- Restart Ghostty or Kitty after terminal configuration changes.
- Run `tmux -V`; this configuration requires tmux 3.3 or newer.
- Run `infocmp tmux-256color` if colors or modified keys are wrong.
- On Ubuntu, rerun bootstrap if the verified Neovim download was interrupted.
- Review [share/TMUX.md](share/TMUX.md) for terminfo and remote-host instructions.
- Review [share/INSTALL.md](share/INSTALL.md) for optional editors, containers, terminals, and CLI tools.

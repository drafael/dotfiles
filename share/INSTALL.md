# Workstation software and optional installations

`bootstrap/bootstrap.sh` installs the daily terminal and Java environment, plus 1Password. This page covers additional setup and software installed separately from the default bootstrap.

## Unattended tool updates

Keep provisioning and updating separate. Bootstrap installs missing tools; `update.sh` updates existing installations:

```sh
cd ~/.dotfiles
./update.sh --scope=bootstrap
./update.sh --scope=all
```

`bootstrap` is the default scope. It selects installed package identities from `bootstrap/packages.sh`, including optional editors, container tools, and tools already present before bootstrap. `all` selects every installed package in supported managers and the same recognized standalone tools. Neither scope scans arbitrary binaries, adds missing top-level tools, modifies project dependencies, pulls configuration repositories, or updates agent plugins/extensions. Package-manager dependencies and dependants may also be installed or upgraded.

Run as your normal user with Python 3 and jq on `PATH`. Missing prerequisites produce status `3`; the script does not install them. Python starts manager commands in a new session with stdin closed, so they cannot use stdin or `/dev/tty` for authentication. Git/SSH askpass helpers are disabled. This is unattended execution, not a sandbox for third-party package code.

### Supported update paths

| Installation owner | Behavior |
| --- | --- |
| Homebrew, including existing Linuxbrew installations | Refresh metadata, select installed packages by scope, then upgrade each eligible package separately. Require the local no-sudo implementation and `--no-ask`/`--no-quit` support. Preserve pins and Homebrew's normal cask auto-update/latest policy. |
| mise | Upgrade installed global requests within their configured constraints, without `--bump` or pruning old runtimes. Recognized writable `~/.local/bin/mise` installations use `self-update --yes --no-plugins`; package-managed mise stays with its owner. Project configuration is not read. A Node installation containing additional npm globals is skipped as `migration-required`, to avoid stranding those tools. |
| npm | Inspect the active global prefix and discovered global mise Node prefixes. Update TypeScript, TypeScript Language Server, tsx, Codex, and npm-installed Pi with lifecycle scripts disabled. Linked packages, downgrade/prerelease transitions, non-writable prefixes, and packages with unreviewed lifecycle requirements are skipped. In `all` scope, unreviewed packages are inventoried and reported, not blindly reinstalled. |
| Claude Code native installation | Run `claude update` only for its recognized, writable user-local version directory. |
| OpenCode native installation | Run `opencode upgrade --method curl` only for its recognized, writable `~/.opencode/bin` installation. |
| Managed Pi | Validate the managed-install marker and run `pi update --no-approve`; do not migrate npm installations or update project resources. |
| Linux user-local LazyGit, Midday Commander, RevDiff | Reuse bootstrap's checksum-verifying release downloader. Stage downloads, compare with the existing binary, and atomically replace recognized writable files in `~/.local/bin`. |
| APT, DNF, pacman, Omarchy system packages, Snap | Inventory selected installed packages and report them as skipped. No sudo or system-update command is executed, even if cached credentials are available. |
| Other standalone installations and manually downloaded fonts | Report recognized tools as skipped; do not guess ownership, overwrite links, rerun installers, or move version pins. |

A Homebrew- or npm-owned agent is handled by that manager, not by a second native updater. GUI apps must be registered with Homebrew to be included in its inventory. If multiple installations shadow one another, the report identifies the package/prefix updated; the script does not change shell configuration or migrate installations.

### Authentication and failures

Homebrew commands receive `HOMEBREW_NO_ASK=1`, `HOMEBREW_NO_SUDO=1`, and the documented no-quit control. Automatic cleanup is disabled for this invocation. Casks with package/custom installers are skipped before upgrade; running apps or other deferred updates are checked afterward and reported rather than claimed as updated. Tap/source trust is never granted automatically.

Updates continue after independent failures. The final summary counts `UPDATED`, `UNCHANGED`, `SKIPPED`, and `FAILED` results:

| Exit status | Meaning |
| --- | --- |
| `0` | No selected targets were blocked and no update failed. `UNCHANGED` means the owning updater made no change or reported no eligible update. |
| `1` | At least one update, inventory, or verification failed; this takes precedence over skipped targets. |
| `2` | Selected targets were skipped, but no update failed. |
| `3` | Invalid arguments, unsupported platform, root execution, or missing setup prerequisites. |

Review the reason for each skip and use the tool's existing updater separately when authentication, trust, or migration is needed. Do not rerun this script with sudo to bypass those decisions. There is no transaction across package managers: a later failure does not roll back successful earlier updates.

`sh tests/update.sh` uses isolated homes and command fixtures to check both scopes, no-terminal execution, installation ownership, pins, partial failures, native update routing, and checksum-tamper rejection. CI runs these checks on macOS, Ubuntu, and Fedora; they do not prove live vendor-updater or GUI-app behavior.

## macOS settings

Review the scripts before running them because they change system preferences:

```sh
~/.dotfiles/bootstrap/mac-defaults.sh
~/.dotfiles/bootstrap/make-macos-ui-fast.sh
~/.dotfiles/bootstrap/set-mac-name.sh NAME
```

`set-mac-name.sh` changes the computer, host, and Bonjour names.

## Alternate terminals

The bootstrap installs Ghostty on macOS and Arch, Kitty on Ubuntu and Fedora, and preserves Foot on Omarchy.

- [Ghostty installation](https://ghostty.org/docs/install/binary)
- [Kitty installation](https://sw.kovidgoyal.net/kitty/binary/)
- [Omarchy terminal selection](https://github.com/basecamp/omarchy/blob/quattro/manual/15-terminal.md)
- [Legacy terminal notes](../legacy/terminals.md)

On Omarchy, install and select a supported terminal through the Omarchy menu or run:

```sh
omarchy default terminal ghostty
omarchy default terminal kitty
```

The repository's Ghostty configuration is tuned for macOS and generic Arch. The Omarchy bootstrap preserves Omarchy's terminal configuration and theme integration.

## Editors and IDEs

Neovim is installed and configured by the main bootstrap. On macOS, install the optional GUI editors only when needed:

```sh
~/.dotfiles/bootstrap/gui-editors.sh
```

The script installs missing IntelliJ IDEA, Visual Studio Code, Cursor, and Zed casks without upgrading existing installations. For Linux, use the editor's official distribution or the desktop's package UI:

- [IntelliJ IDEA](https://www.jetbrains.com/idea/download/)
- [Visual Studio Code](https://code.visualstudio.com/docs/setup/linux)
- [Cursor](https://www.cursor.com/downloads)
- [Zed](https://zed.dev/docs/linux)

Omarchy exposes supported editors under **Install > Editor**.

## 1Password

The default bootstrap installs the 1Password desktop app and CLI (`op`). On a headless Linux VM, install only the CLI:

```sh
~/.dotfiles/bootstrap/bootstrap.sh --onepassword-cli-only
```

Run just the 1Password category with `~/.dotfiles/bootstrap/1password.sh` or `~/.dotfiles/bootstrap/1password.sh --cli-only`. A session without a display is not necessarily headless (for example, SSH into a desktop), so select CLI-only explicitly. The scripts install missing packages without upgrading existing ones; they do not sign in, unlock a vault, or change SSH-agent configuration. After installation they check the vendor's current stable CLI version when `curl` and `jq` are available; an older `op` produces a warning, not an upgrade or failure. A version match alone does not prove an existing installation's provenance.

macOS uses Homebrew casks and checks the installed app and CLI code signatures against 1Password's Apple signing team (the desktop app must be in a standard Applications directory for this check). Ubuntu uses 1Password's signed APT repository and checks the signing-key fingerprint before configuring it. For missing 1Password packages, it pins `1password` and `1password-cli` to the vendor's APT host, rejects other repositories, and stops if the chosen version appears in more than one source. Already-installed packages are left untouched; APT and dpkg do not establish where they were originally downloaded. A conflicting existing 1Password APT source or preferences file causes the script to stop rather than replace it. The repository supplies both packages on amd64 and only the CLI on arm64. For an Ubuntu arm64 desktop, follow the vendor's [signed ARM64 tarball instructions](https://support.1password.com/install-linux/#arm-or-other-distributions-targz) separately. Fedora Workstation x86-64 installs both packages from 1Password's signed RPM repository; Fedora aarch64 provides only the CLI RPM. The script verifies the vendor key's pinned fingerprint before importing it, requires signed packages and repository metadata, and requests missing packages specifically from the vendor repository. A conflicting repository or key file stops the install rather than being replaced. For a Fedora aarch64 desktop, bootstrap the CLI with `--onepassword-cli-only` first, then follow the vendor's [signed ARM64 tarball instructions](https://support.1password.com/install-linux/#arm-or-other-distributions-targz) separately. Keep using CLI-only for later bootstrap runs; bootstrap does not install or update that desktop tarball and refuses to install missing RPM packages over unowned vendor files. Omarchy x86-64 installs its signed repository packages through `omarchy pkg add`, without opening the app or installing a Chromium extension. For Omarchy's extension and launcher setup, use **Install > Service > 1Password** instead.

### Arch and Omarchy ARM64: verified vendor releases

Plain Arch and Omarchy ARM64 download 1Password's [Linux desktop tarball and detached signature](https://support.1password.com/install-linux/#arm-or-other-distributions-targz), plus the official [CLI release containing `op` and `op.sig`](https://developer.1password.com/docs/cli/get-started/). The script verifies the signing key's published fingerprint (`3FEF9748469ADBE15DA7CA80AC2D62742012EA22`) and verifies each release in an isolated keyring before installing that component. It checks that freshly installed desktop and CLI binaries match the signed downloads and that the new CLI reports the signed release's version. It does not execute an AUR recipe. The desktop app is copied into `/opt/1Password`, then its vendor-supplied `after-install.sh` runs with `sudo`. The CLI installs as a root-owned `/usr/local/bin/op`; for desktop integration the script applies the vendor's `onepassword-cli` group and setgid permissions. CLI-only installs omit those desktop permissions.

Already-installed components are left untouched. When a vendor component is missing, the vendor path rejects any existing pacman-managed 1Password package rather than mixing package-manager files with manual installation. It also refuses to overwrite an existing `/opt/1Password` directory or `/usr/local/bin/op`. If migrating from AUR or another package, plan its removal and replacement separately; bootstrap will not remove package-managed files to force a switch.

**Updates are manual on these two paths.** The bootstrap ensures the binaries are present but does not upgrade them, and `omarchy update` cannot update vendor-installed files. Monitor 1Password releases and follow its [tarball update instructions](https://support.1password.com/update-1password/) to download, verify, and reinstall newer signed releases when needed. Omarchy x86-64 keeps its normal package-managed update path.

After desktop installation, sign in using the app. To authenticate the CLI through the desktop app, enable **Integrate with 1Password CLI** under **Settings > Developer**. On Linux, also enable **Unlock using system authentication** under **Settings > Security**. For a CLI-only VM, follow [1Password's CLI sign-in instructions](https://developer.1password.com/docs/cli/get-started/) rather than expecting desktop integration. Check installation with `op --version`; commands that access vaults require authentication.

## Container tools

Container tooling is optional and is not part of the default bootstrap. Install the Docker-compatible stack:

```sh
~/.dotfiles/bootstrap/containers.sh
```

This installs Colima and the Docker CLI on macOS, Docker Engine from the platform repository on Ubuntu, Fedora, and Arch, and preserves Omarchy's native Docker setup. Compose v2, Buildx, kubectl, Helm, and Minikube are included. Ubuntu and Fedora use architecture-specific upstream Kubernetes tool releases with published SHA-256 verification.

Select Podman instead when needed:

```sh
~/.dotfiles/bootstrap/containers.sh --runtime=podman
```

The script verifies client commands but does not deliberately start or enable services, initialize a VM, grant Docker group access, or create a Kubernetes cluster. The platform package manager may apply its normal service defaults while installing Docker.

Start the selected runtime separately:

- macOS with Docker: `colima start`
- macOS with Podman: `podman machine init && podman machine start`
- Ubuntu, Fedora, or Arch with Docker: `sudo systemctl enable --now docker`
- Linux with Podman: run `podman info`; its native mode is rootless
- Omarchy: keep using `sudo docker`, or review **Setup > Security > Sudoless Docker** before changing access

Docker group membership grants root-equivalent access and is never changed by the script. After the runtime works without elevated privileges, create an isolated local cluster with `minikube start --driver=docker`. The Podman driver is available through `minikube start --driver=podman` but remains experimental. Colima's built-in Kubernetes support is also available through `colima start --kubernetes` when a separate Minikube cluster is unnecessary.

## Additional command-line tools

The main bootstrap installs btop, htop, LazyGit, Tig, Midnight Commander, Yazi, Midday Commander (`mdc`), jq, tree, and wget. It also installs Yazi's recommended preview dependencies. On Ubuntu and Fedora, unavailable optional dependencies such as `resvg` produce a warning. Fedora installs Yazi from a checksum-verified official release instead of a community COPR; if `wget` is absent, it installs Fedora's `wget1-wget` package.

The fonts category installs Fira Code, JetBrains Mono, Cascadia Code, Source Code Pro, Hack, FiraCode Nerd Font, and the regular and monospace symbols-only Nerd Fonts. macOS uses Homebrew casks. Arch and Omarchy use their signed platform packages; Omarchy's selected system font remains unchanged. Ubuntu installs Fira Code, JetBrains Mono, Cascadia Code, and Hack from APT. Because Ubuntu 24.04 does not package Source Code Pro, the script installs Adobe's pinned, checksum-verified OpenType release under `${XDG_DATA_HOME:-$HOME/.local/share}/fonts`. Ubuntu and Fedora install checksum-verified Nerd Fonts release archives under `${XDG_DATA_HOME:-$HOME/.local/share}/fonts` and copy the upstream Fontconfig fallback configuration to `${XDG_CONFIG_HOME:-$HOME/.config}/fontconfig/conf.d`. Fedora installs the five programming font families from its package repositories.

Yazi and Neovim emit Nerd Font icon glyphs but rely on their host terminal to render them. The Ghostty, Kitty, WezTerm, and Zed terminal configurations use `Symbols Nerd Font Mono` as a fallback while preserving their primary text font. Linux also installs the Nerd Fonts Fontconfig fallback for Foot and other Fontconfig-based applications. Restart the terminal after installing or changing fonts.

Install these only when a project or workflow needs them:

| Tool | Purpose |
| --- | --- |
| `httpie` | Alternative HTTP client |
| `mpv` | Media playback |
| `ncdu` | Disk usage analysis |
| `nmap` | Network inspection |
| `shellcheck` | Shell script analysis |

Use Homebrew on macOS, `apt` on Ubuntu, `dnf` on Fedora, `pacman` on Arch, or `omarchy pkg add` on Omarchy. Bootstrap links tracked configuration even when the corresponding optional tool is not installed.

## Productivity notes

See [PRODUCTIVITY.md](PRODUCTIVITY.md) for keyboard and workflow notes.

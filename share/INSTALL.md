# Optional workstation software

`bootstrap/bootstrap.sh` installs the daily terminal and Java environment. Use this page for software that is useful on some workstations but does not belong in the default bootstrap.

## macOS settings

Review the scripts before running them because they change system preferences:

```sh
~/.dotfiles/bootstrap/mac-defaults.sh
~/.dotfiles/bootstrap/make-macos-ui-fast.sh
~/.dotfiles/bootstrap/set-mac-name.sh NAME
```

`set-mac-name.sh` changes the computer, host, and Bonjour names.

## Alternate terminals

The bootstrap installs Ghostty on macOS and Arch, Kitty on Ubuntu, and preserves Foot on Omarchy.

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

## Container tools

Container tooling is optional and is not part of the default bootstrap. Install the Docker-compatible stack:

```sh
~/.dotfiles/bootstrap/containers.sh
```

This installs Colima and the Docker CLI on macOS, Docker Engine from the platform repository on Ubuntu and Arch, and preserves Omarchy's native Docker setup. Compose v2, Buildx, kubectl, Helm, and Minikube are included. Ubuntu's Kubernetes tools use architecture-specific upstream releases with published SHA-256 verification.

Select Podman instead when needed:

```sh
~/.dotfiles/bootstrap/containers.sh --runtime=podman
```

The script verifies client commands but does not deliberately start or enable services, initialize a VM, grant Docker group access, or create a Kubernetes cluster. Ubuntu's package manager may apply its normal service defaults while installing Docker.

Start the selected runtime separately:

- macOS with Docker: `colima start`
- macOS with Podman: `podman machine init && podman machine start`
- Ubuntu or Arch with Docker: `sudo systemctl enable --now docker`
- Linux with Podman: run `podman info`; its native mode is rootless
- Omarchy: keep using `sudo docker`, or review **Setup > Security > Sudoless Docker** before changing access

Docker group membership grants root-equivalent access and is never changed by the script. After the runtime works without elevated privileges, create an isolated local cluster with `minikube start --driver=docker`. The Podman driver is available through `minikube start --driver=podman` but remains experimental. Colima's built-in Kubernetes support is also available through `colima start --kubernetes` when a separate Minikube cluster is unnecessary.

## Additional command-line tools

The main bootstrap installs btop, htop, LazyGit, Tig, Midnight Commander, Yazi, Midday Commander (`mdc`), jq, tree, and wget. It also installs Yazi's recommended preview dependencies. On Ubuntu, unavailable optional dependencies such as `resvg` produce a warning.

The fonts category installs Fira Code, FiraCode Nerd Font, and the regular and monospace symbols-only Nerd Fonts. macOS uses Homebrew casks. Arch and Omarchy use their signed platform packages; Omarchy's selected system font remains unchanged. Ubuntu installs regular Fira Code from APT and checksummed Nerd Fonts release archives under `${XDG_DATA_HOME:-$HOME/.local/share}/fonts`, with the upstream Fontconfig fallback configuration under `${XDG_CONFIG_HOME:-$HOME/.config}/fontconfig/conf.d`.

Yazi's icons require Nerd Font glyphs. Use `FiraCode Nerd Font Mono` as the terminal's primary font, or keep another primary font and configure `Symbols Nerd Font Mono` as its fallback. Restart the terminal after changing fonts.

Install these only when a project or workflow needs them:

| Tool | Purpose |
| --- | --- |
| `httpie` | Alternative HTTP client |
| `mpv` | Media playback |
| `ncdu` | Disk usage analysis |
| `nmap` | Network inspection |
| `shellcheck` | Shell script analysis |

Use Homebrew on macOS, `apt` on Ubuntu, `pacman` on Arch, or `omarchy pkg add` on Omarchy. Bootstrap links tracked configuration even when the corresponding optional tool is not installed.

## Productivity notes

See [PRODUCTIVITY.md](PRODUCTIVITY.md) for keyboard and workflow notes.

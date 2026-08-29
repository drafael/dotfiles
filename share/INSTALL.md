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

Neovim is installed and configured by the main bootstrap. Install other editors only when needed:

```sh
# macOS
brew install --cask intellij-idea visual-studio-code cursor zed
```

For Linux, use the editor's official distribution or the desktop's package UI:

- [IntelliJ IDEA](https://www.jetbrains.com/idea/download/)
- [Visual Studio Code](https://code.visualstudio.com/docs/setup/linux)
- [Cursor](https://www.cursor.com/downloads)
- [Zed](https://zed.dev/docs/linux)

Omarchy exposes supported editors under **Install > Editor**.

## Container tools

On macOS, Colima provides a lightweight Docker-compatible runtime:

```sh
brew install colima docker docker-compose kubectl helm
colima start
```

Other options:

- [Docker Engine on Ubuntu](https://docs.docker.com/engine/install/ubuntu/)
- [Docker on Arch Linux](https://wiki.archlinux.org/title/Docker)
- [Podman](https://podman.io/docs/installation)
- [Minikube](https://minikube.sigs.k8s.io/docs/start/)

Omarchy already includes Docker and Docker Compose. Its default configuration requires `sudo`; review the Omarchy security guidance before enabling sudoless Docker.

## Additional command-line tools

Install these only when a project or workflow needs them:

| Tool | Purpose |
| --- | --- |
| `btop` or `htop` | Process and resource monitoring |
| `jq` | JSON processing |
| `lazygit` or `tig` | Terminal Git interfaces with included Catppuccin Frappé configurations |
| `mc` or `yazi` | Terminal file management |
| `ncdu` | Disk usage analysis |
| `nmap` | Network inspection |
| `shellcheck` | Shell script analysis |
| `tree` | Directory trees |
| `wget` or `httpie` | HTTP downloads and requests |

Use Homebrew on macOS, `apt` on Ubuntu, `pacman` on Arch, or `omarchy pkg add` on Omarchy.

## Productivity notes

See [PRODUCTIVITY.md](PRODUCTIVITY.md) for keyboard and workflow notes.

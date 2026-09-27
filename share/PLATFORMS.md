# Supported platforms

| Platform | Shell | Terminal | Coding agents |
| --- | --- | --- | --- |
| macOS | Zsh | Ghostty | Official installers |
| Ubuntu 24.04+ | Zsh | Kitty | Official installers |
| Fedora Workstation 43+ (mutable) | Zsh | Kitty | Official installers |
| Arch Linux | Zsh | Ghostty | Official installers |
| Omarchy 4 | Bash | Foot | Omarchy lazy launchers |

Fedora Atomic/rpm-ostree is not supported: this bootstrap expects a writable, DNF-managed workstation. On Fedora aarch64 the 1Password RPM repository provides only the CLI, so use `--onepassword-cli-only` or install the signed ARM64 desktop tarball separately. See [INSTALL.md](INSTALL.md#1password).

Omarchy keeps its native shell, terminal, desktop theme integration, package lifecycle, and agent launchers. The bootstrap applies the portable Git, tmux, Neovim, aliases, and environment configuration there.

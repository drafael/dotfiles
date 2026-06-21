
## Prerequisites

* macOS
* [Homebrew](http://brew.sh) package manager

## Installation

Clone to `~/.dotfiles`

## Shell Environment

### Zsh

```sh
ln -s ~/.dotfiles/.zshrc ~/.zshrc
```

### Shell Prompt

This dotfiles setup uses [Starship](https://starship.rs) (if installed) or [Pure](https://github.com/sindresorhus/pure#pure) as the shell prompt.

```sh
brew install starship
```

## Terminal Emulators

### [iTerm2](http://iterm2.com)

```sh
brew install --cask iterm2
```
Point your preferences to `~/.dotfiles/iTerm2/com.googlecode.iterm2.plist`

![iTerm2-settings](iTerm2/iTerm2-settings.png)

### [Ghostty](https://ghostty.org/)

Fast cross-platform terminal emulator that uses platform-native UI and GPU acceleration.

```sh
brew install --cask ghostty
```
```sh
ln -s ~/.dotfiles/.config/ghostty ~/.config/ghostty
```

### [WezTerm](https://wezterm.org/)

```sh
brew install --cask wezterm
```
```sh
ln -s ~/.dotfiles/.config/wezterm ~/.config/wezterm
```

### [Kitty](https://sw.kovidgoyal.net/kitty/)

GPU-based terminal emulator. Config is a 1:1 port of the Ghostty setup (Catppuccin Frappé, splits).

```sh
brew install --cask kitty
```
```sh
mkdir -p ~/.config/kitty && ln -sfn ~/.dotfiles/.config/kitty/kitty.conf ~/.config/kitty/kitty.conf
```

### [Warp](https://warp.dev/)

```sh
brew install --cask warp
```
```sh
ln -s ~/.dotfiles/.warp ~/.warp
```

## [Tmux](https://github.com/tmux/tmux/wiki)

```sh
brew install tmux
```

[Tmux Plugin Manager](https://github.com/tmux-plugins/tpm):
```sh
git clone https://github.com/tmux-plugins/tpm ~/.config/tmux/plugins/tpm
```
```sh
ln -s ~/.dotfiles/.config/tmux ~/.config/tmux
```
Start new session `tmux` and install plugins `prefix` + `I`, where prefix is `Ctrl` + `Space`

## Git

Put in `~/.gitconfig.local` sensitive information such as the `git` user credentials, e.g.:

```
[user]
    name = Denys Rafael
    email = denys@example.com
```

and then

```sh
ln -s ~/.dotfiles/.gitconfig ~/.gitconfig && ln -s ~/.dotfiles/.gitignore_global ~/.gitignore_global && ln -s ~/.dotfiles/.gitignore_global ~/.gitignore
```

In order to view all of my configured aliases enter `git aliases`

## Code Editors

### [NeoVim](https://neovim.io/)

```sh
brew install neovim
```

[Kickstart](https://github.com/nvim-lua/kickstart.nvim) based configuration:
```sh
ln -s ~/.dotfiles/.config/nvim ~/.config/nvim
```

### [Visual Studio Code](https://code.visualstudio.com/) and Forks

```sh
brew install --cask visual-studio-code
```

```sh
brew install --cask cursor
```

### [Zed](https://zed.dev/)

```sh
brew install --cask zed
```

```sh
mkdir -p $HOME/.config/zed && ln -s $HOME/.dotfiles/.config/zed/settings.json $HOME/.config/zed/settings.json
```

### [EditorConfig](https://editorconfig.org/)

```sh
brew install editorconfig
```

## Java Dev Tools

### OpenJDK

```sh
brew install openjdk@21
```
```sh
sudo ln -sfn $(brew --prefix)/opt/openjdk@21/libexec/openjdk.jdk /Library/Java/JavaVirtualMachines/openjdk-21.jdk
```

Set `JAVA_HOME` in `.zshrc` or `.bash_profile`:
```sh
if [ -x "$(command -v java)" ]; then
  export JAVA_HOME=$(/usr/libexec/java_home -v 21)
  export PATH=$JAVA_HOME/bin:$PATH
fi
```

### Java Build Tools

```sh
brew install ant maven gradle
```

### [IntelliJ IDEA](https://www.jetbrains.com/idea/)

```sh
brew install --cask intellij-idea
```

## Container Runtimes

### Docker and [Minikube](https://github.com/kubernetes/minikube)

```sh
brew install docker docker-compose minikube kubectl helm
```

### [Colima](https://github.com/abiosoft/colima)

```sh
brew install colima
```
Start container runtime: `colima start` or `colima start --kubernetes`.

### [Podman](https://podman.io/)

```sh
brew install podman podman-compose podman-desktop
```

## AI Coding Agents

My AI coding-agent setup now lives in a separate repository: [drafael/coding-harness](https://github.com/drafael/coding-harness).

## See Also

* [GitHub does dotfiles](https://dotfiles.github.io/)
* [Awesome Awesomeness](https://github.com/bayandin/awesome-awesomeness): [Dotfiles](https://github.com/webpro/awesome-dotfiles), [Shell](https://github.com/alebcay/awesome-shell), [Dev Env](https://github.com/jondot/awesome-devenv), [Java](https://github.com/akullpp/awesome-java)
* [Command-Line Tools](share/INSTALL.md#command-line-tools)
* [Productivity Tips](share/PRODUCTIVITY.md)

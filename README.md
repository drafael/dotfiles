
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
Modified [oh-my-zsh](https://github.com/ohmyzsh/ohmyzsh) with [minimal prompt](https://github.com/sindresorhus/pure#pure).

### Bash

```sh
ln -s ~/.dotfiles/.bashrc ~/.bashrc && ln -s ~/.dotfiles/.bash_profile ~/.bash_profile
```
## Terminal Emulators

### [iTerm2](http://iterm2.com)

```sh
brew install --cask iterm2
```
Point your preferences to `~/.dotfiles/iTerm2/com.googlecode.iterm2.plist`

### [Ghostty](https://ghostty.org/)

Fast cross-platform terminal emulator that uses platform-native UI and GPU acceleration.

```sh
brew install --cask ghostty
```
```sh
ln -s $HOME/.dotfiles/.config/ghostty $HOME/.config/ghostty
```

### [Warp](https://warp.dev/)

```sh
brew install --cask warp
```
```sh
ln -s $HOME/.dotfiles/.warp $HOME/.warp
```

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

### [Zed](https://zed.dev/)

```sh
brew install --cask zed
```

```sh
mkdir -p $HOME/.config/zed && ln -s $HOME/.dotfiles/.config/zed/settings.json $HOME/.config/zed/settings.json
```

### [Visual Studio Code](https://code.visualstudio.com/)

```sh
brew install --cask visual-studio-code
```

[Make your own custom AI code assistant](share/AI_CODE_ASSISTANT.md)

### Vim

[Installation or upgrading](share/INSTALL.md#vim):

```sh
brew install vim
```

Syncing [.vimrc](.vimrc) and [plugins](share/INSTALL.md#my-favorite-vim-plugins):

```sh
ln -s ~/.dotfiles/.vimrc ~/.vimrc && vim +PluginInstall +qall
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


## See Also

* [GitHub does dotfiles](https://dotfiles.github.io/)
* [Awesome Awesomeness](https://github.com/bayandin/awesome-awesomeness): [Dotfiles](https://github.com/webpro/awesome-dotfiles), [Shell](https://github.com/alebcay/awesome-shell), [Dev Env](https://github.com/jondot/awesome-devenv), [Java](https://github.com/akullpp/awesome-java)
* [Command-Line Tools](share/INSTALL.md#command-line-tools)
* [Productivity Tips](share/PRODUCTIVITY.md)

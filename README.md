
## Prerequisites

* macOS
* Command Line Tools (CLT) for Xcode: `xcode-select --install`
* [Homebrew](http://brew.sh) package manager

## Installation

Clone to `~/.dotfiles`

## Zsh

```sh
ln -s ~/.dotfiles/.zshrc ~/.zshrc
```
Modified [oh-my-zsh](https://github.com/ohmyzsh/ohmyzsh) with [minimal prompt](https://github.com/sindresorhus/pure#pure).

## Bash

```sh
ln -s ~/.dotfiles/.bashrc ~/.bashrc && ln -s ~/.dotfiles/.bash_profile ~/.bash_profile
```

## [iTerm2](http://iterm2.com)

Install `brew install iterm2` and point your preferences to `~/.dotfiles/iTerm2/com.googlecode.iterm2.plist`

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
brew install zed
```

### [Visual Studio Code](https://code.visualstudio.com/)

```sh
brew install visual-studio-code
```

AI code assistant plugins: [Continue](https://www.continue.dev) and [Llama Coder](https://marketplace.visualstudio.com/items?itemName=ex3ndr.llama-coder)

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
brew install openjdk@17
```
```sh
sudo ln -sfn $(brew --prefix)/opt/openjdk@17/libexec/openjdk.jdk /Library/Java/JavaVirtualMachines/openjdk-17.jdk
```

Set `JAVA_HOME` in `.zshrc` or `.bash_profile`:
```sh
if [ -x "$(command -v java)" ]; then
  export JAVA_HOME=$(/usr/libexec/java_home -v 17)
  export PATH=$JAVA_HOME/bin:$PATH
fi
```

### Java Build Tools

```sh
brew install ant maven gradle
```

### [IntelliJ IDEA](https://www.jetbrains.com/idea/)

```sh
brew install intellij-idea
```

AI code assistant plugins: [Continue](https://www.continue.dev) and [CodeGPT](https://plugins.jetbrains.com/plugin/21056-codegpt)

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

* [Command-Line Tools](share/INSTALL.md#command-line-tools)
* [Productivity Tips](share/PRODUCTIVITY.md)

## Acknowledgements

Inspiration and code was taken (stolen) from many sources, including:
* [GitHub does dotfiles](https://dotfiles.github.io/)
* [@mathiasbynens](https://github.com/mathiasbynens) (Mathias Bynens) [dotfiles](https://github.com/mathiasbynens/dotfiles)
* [@garybernhardt](https://github.com/garybernhardt) (Gary Bernhardt) [dotfiles](https://github.com/garybernhardt/dotfiles)
* [@necolas](https://github.com/necolas) (Nicolas Gallagher) [dotfiles](https://github.com/necolas/dotfiles)
* [Awesome Awesomeness](https://github.com/bayandin/awesome-awesomeness): [Dotfiles](https://github.com/webpro/awesome-dotfiles), [Shell](https://github.com/alebcay/awesome-shell), [Dev Env](https://github.com/jondot/awesome-devenv), [Java](https://github.com/akullpp/awesome-java)

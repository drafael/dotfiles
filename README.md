
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

### [NeoVim](https://neovim.io/) with [Kickstart](https://github.com/nvim-lua/kickstart.nvim) Configuration

```sh
brew install neovim
```

```sh
ln -s ~/.dotfiles/.config/nvim ~/.config/nvim
```

### [Visual Studio Code](https://code.visualstudio.com/)

```sh
brew install --cask visual-studio-code
```

[Make your own custom AI code assistant](share/AI_CODE_ASSISTANT.md)

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

## AI Agents

### [GitHub Copilot CLI](https://github.com/github/copilot-cli)

[Installation](https://github.com/github/copilot-cli?tab=readme-ov-file#installation):
```sh
npm install -g @github/copilot
```

Global [personal custom instructions](https://docs.github.com/en/copilot/how-tos/configure-custom-instructions/add-personal-instructions) for GitHub Copilot
```sh
ln -s ~/.dotfiles/.copilot/copilot-instructions.md ~/.copilot/copilot-instructions.md
```

### [Claude Code](https://docs.anthropic.com/en/docs/claude-code/overview)

[Installation](https://docs.anthropic.com/en/docs/claude-code/quickstart#step-1%3A-install-claude-code):
```sh
brew install claude-code
```

Global [context (memory) file](https://docs.anthropic.com/en/docs/claude-code/memory) for instructions that apply to all projects:
```sh
ln -s ~/.dotfiles/.claude/CLAUDE.md ~/.claude/CLAUDE.md
```

[Settings file](https://docs.anthropic.com/en/docs/claude-code/settings#settings-files) for all projects:
```sh
ln -s ~/.dotfiles/.claude/settings.json ~/.claude/settings.json
```

Global [custom commands](https://docs.anthropic.com/en/docs/claude-code/slash-commands#custom-slash-commands):
```sh
ln -s ~/.dotfiles/.claude/commands ~/.claude/commands
```

### [Gemini CLI](https://github.com/google-gemini/gemini-cli#gemini-cli)

[Installation](https://github.com/google-gemini/gemini-cli#-installation):
```sh
brew install gemini-cli
```

Global [context file](https://github.com/google-gemini/gemini-cli/blob/main/docs/cli/configuration.md#context-files-hierarchical-instructional-context) for instructions that apply to all projects:
```sh
ln -s ~/.dotfiles/.gemini/GEMINI.md ~/.gemini/GEMINI.md
```

Global [custom commands](https://github.com/google-gemini/gemini-cli/blob/main/docs/cli/commands.md#custom-commands):
```sh
ln -s ~/.dotfiles/.gemini/commands ~/.gemini/commands
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

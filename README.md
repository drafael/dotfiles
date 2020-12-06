
## Prerequisites

* macOS
* Command Line Tools (CLT) for Xcode <https://developer.apple.com/downloads> or [Xcode](https://itunes.apple.com/us/app/xcode/id497799835)
* [Homebrew](http://brew.sh) package manager

## Installation

Clone to `~/.dotfiles`

## Zsh

```bash
ln -s ~/.dotfiles/.zshrc ~/.zshrc
```

## Bash

```bash
ln -s ~/.dotfiles/.bashrc ~/.bashrc
ln -s ~/.dotfiles/.bash_profile ~/.bash_profile
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

```bash
ln -s ~/.dotfiles/.gitconfig ~/.gitconfig
ln -s ~/.dotfiles/.gitignore_global ~/.gitignore_global
ln -s ~/.dotfiles/.gitignore_global ~/.gitignore
```

In order to view all of my configured aliases enter `git aliases`

## Vim

Syncing [.vimrc](.vimrc) and [plugins](share/INSTALL.md#my-favorite-vim-plugins)

```bash
ln -s ~/.dotfiles/.vimrc ~/.vimrc
vim +PluginInstall +qall
```

## [Spacemacs](https://www.spacemacs.org/)

```bash
git clone https://github.com/syl20bnr/spacemacs ~/.emacs.d
ln -s ~/.dotfiles/.spacemacs ~/.spacemacs
```

## [Sublime Text](https://www.sublimetext.com/)

Installation `brew install sublime-text`

[Package Control](https://packagecontrol.io/) — the first thing to do after the ST installation is to setup the package manager
* [Installation](https://packagecontrol.io/installation) (manual)
```bash
cd ~/Library/Application\ Support/Sublime\ Text\ 3/
rm -r Installed\ Packages/
ln -s ~/.dotfiles/Library/Application\ Support/Sublime\ Text\ 3/Installed\ Packages/
```
* [Syncing](https://packagecontrol.io/docs/syncing)
```bash
cd ~/Library/Application\ Support/Sublime\ Text\ 3/Packages/
rm -r User
ln -s ~/.dotfiles/Library/Application\ Support/Sublime\ Text\ 3/Packages/User/
```
Also take a look awesome [Quick Start Guides](https://github.com/dreikanter/sublime-bookmarks)

## Workstation Setup

* [Vim](share/INSTALL.md#vim)
* [Command-Line Tools](share/INSTALL.md#command-line-tools)
* [Java Dev Env](share/INSTALL.md#java-dev-env)
* [Productivity Tips](share/PRODUCTIVITY.md)

## Acknowledgements

Inspiration and code was taken (stolen) from many sources, including:
* [GitHub does dotfiles](https://dotfiles.github.io/)
* [@mathiasbynens](https://github.com/mathiasbynens) (Mathias Bynens) [dotfiles](https://github.com/mathiasbynens/dotfiles)
* [@garybernhardt](https://github.com/garybernhardt) (Gary Bernhardt) [dotfiles](https://github.com/garybernhardt/dotfiles)
* [@necolas](https://github.com/necolas) (Nicolas Gallagher) [dotfiles](https://github.com/necolas/dotfiles)
* [Awesome Awesomeness](https://github.com/bayandin/awesome-awesomeness): [Dotfiles](https://github.com/webpro/awesome-dotfiles), [Shell](https://github.com/alebcay/awesome-shell), [Dev Env](https://github.com/jondot/awesome-devenv), [Java](https://github.com/akullpp/awesome-java)
* Good looking console emulators for Windows: [cmder](http://cmder.net/), [ConEmu](https://conemu.github.io/), [mintty](http://mintty.github.io/)


## Requirements
* macOS
* [Homebrew](http://brew.sh) package manager
* [Homebrew-Cask](https://github.com/caskroom/homebrew-cask#homebrew-cask) for Mac applications distributed as binaries
  - Installation `brew tap caskroom/cask`

## Installation
Clone to `~/dotfiles`

## Bash

```bash
ln -s ~/dotfiles/.bashrc ~/.bashrc
ln -s ~/dotfiles/.bash_profile ~/.bash_profile
source ~/.bashrc
```
I use a custom bash prompt (with colors, Git statuses, and Git branches)
created by [@necolas](https://github.com/necolas) and based on the [Solarized](http://ethanschoonover.com/solarized) color palette. For best results, you should install
[iTerm2](http://iterm2.com) and import [Solarized Dark colors](https://github.com/altercation/solarized/tree/master/iterm2-colors-solarized)
or simply [use my preferences](https://github.com/drafael/dotfiles#iterm2).

![Screenshot:](https://github.com/drafael/dotfiles/raw/master/share/custom-bash-prompt.png)

## [iTerm2](http://iterm2.com)
Install `brew cask install iterm2` and point your preferences to `~/dotfiles/iTerm2/com.googlecode.iterm2.plist`

## Vim
Installation `brew install vim --with-override-system-vi`

## [MacVim](http://macvim-dev.github.io/macvim)
Installation `brew cask install macvim`

## Syncing [.vimrc](https://github.com/drafael/dotfiles/blob/master/.vimrc), [plugins](http://vimawesome.com/) and [colors](http://vimcolors.com/):
```bash
ln -s ~/dotfiles/.vimrc ~/.vimrc
vim +PluginInstall +qall
```
  - [x] [Vundle](https://github.com/VundleVim/Vundle.vim#about) - plugin manager
  - [x] [Airline](https://github.com/vim-airline/vim-airline#vim-airline-) - status bar
  - [x] [vim-colors-solarized](https://github.com/altercation/vim-colors-solarized#screenshots)
  - [x] [CtrlP](https://github.com/ctrlpvim/ctrlp.vim#ctrlpvim) - fuzzy file finder, buffer switcher, MRU
  - [x] [Snipmate](https://github.com/garbas/vim-snipmate#snipmate) - [Snippet](https://github.com/honza/vim-snippets#snipmate--ultisnip-snippets) manager for vim
  - [x] [Syntastic](https://github.com/vim-syntastic/syntastic) - syntax checking hacks for vim
  - [ ] [vim-polyglot](https://github.com/sheerun/vim-polyglot#vim-polyglot--) - meta-plugin for syntaxes
  - [x] [vim-rooter](https://github.com/airblade/vim-rooter#rooter) - changes working directory to project root
  - [x] [vim-better-whitespace](https://github.com/ntpeters/vim-better-whitespace#vim-better-whitespace-plugin) - better whitespace highlighting
  - [x] [indentLine](https://github.com/Yggdroot/indentLine#indentline) - display the indention levels with thin vertical lines

## [Sublime Text](https://www.sublimetext.com/)
Installation `brew cask install sublime-text`

[Package Control](https://packagecontrol.io/) — the first thing to do after the ST installation is to setup the package manager
* [Installation](https://packagecontrol.io/installation) (manual)
```bash
cd ~/Library/Application\ Support/Sublime\ Text\ 3/
rm -r Installed\ Packages/
ln -s ~/dotfiles/Library/Application\ Support/Sublime\ Text\ 3/Installed\ Packages/
```
* [Syncing](https://packagecontrol.io/docs/syncing)
```bash
cd ~/Library/Application\ Support/Sublime\ Text\ 3/Packages/
rm -r User
ln -s ~/dotfiles/Library/Application\ Support/Sublime\ Text\ 3/Packages/User/
```
Also take a look awesome [Quick Start Guides](https://github.com/dreikanter/sublime-bookmarks)

## Workstation Setup
* [Command-Line Tools](https://github.com/drafael/dotfiles/blob/master/share/INSTALL.md#command-line-tools)
* [Java Dev Env](https://github.com/drafael/dotfiles/blob/master/share/INSTALL.md#java-dev-env)
* [Automated Setup](https://github.com/drafael/osx-bootstrap) `~/dotfiles/bin/bootstrap.sh`

## Acknowledgements

Inspiration and code was taken (stolen) from many sources, including:
* [@mathiasbynens](https://github.com/mathiasbynens) (Mathias Bynens) [dotfiles](https://github.com/mathiasbynens/dotfiles)
* [@garybernhardt](https://github.com/garybernhardt) (Gary Bernhardt) [dotfiles](https://github.com/garybernhardt/dotfiles)
* [@necolas](https://github.com/necolas) (Nicolas Gallagher) [dotfiles](https://github.com/necolas/dotfiles)
* [GitHub does dotfiles](https://dotfiles.github.io/)
* [Awesome Awesomeness](https://github.com/bayandin/awesome-awesomeness): [Dotfiles](https://github.com/webpro/awesome-dotfiles), [Shell](https://github.com/alebcay/awesome-shell), [Dev Env](https://github.com/jondot/awesome-devenv), [Java](https://github.com/akullpp/awesome-java)
* Good looking console emulators for Windows: [cmder](http://cmder.net/), [ConEmu](https://conemu.github.io/), [mintty](http://mintty.github.io/)


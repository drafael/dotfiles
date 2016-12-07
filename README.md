## Installation

`git clone git://github.com/drafael/dotfiles.git ~/dotfiles`

## Bash

```bash
ln -s ~/dotfiles/.bashrc ~/.bashrc
ln -s ~/dotfiles/.bash_profile ~/.bash_profile
```
I use a [custom bash prompt](https://github.com/necolas/dotfiles#custom-bash-prompt) (with colors, Git statuses, and Git branches)
created by @necolas and based on the [Solarized](http://ethanschoonover.com/solarized) color palette. For best results, you should install
[iTerm2](http://iterm2.com) and import [Solarized Dark colors](https://github.com/altercation/solarized/tree/master/iterm2-colors-solarized)
or just use my preferences file (see bellow).

![Screenshot:](https://github.com/drafael/dotfiles/raw/master/share/custom-bash-prompt.png)

## [iTerm2](http://iterm2.com)

Point your preferences to `~/dotfiles/iTerm2/com.googlecode.iterm2.plist`

## Vim or [MacVim](http://macvim-dev.github.io/macvim)

```bash
ln -s ~/dotfiles/.vimrc ~/.vimrc
vim +PluginInstall +qall
```
[Awesome Vim Plugins](http://vimawesome.com/) and [Colors](http://vimcolors.com/):
  - [x] [Vundle](https://github.com/VundleVim/Vundle.vim) — plugin manager
  - [x] [Airline](https://github.com/vim-airline/vim-airline) — status bar
  - [x] [vim-colors-solarized](https://github.com/altercation/vim-colors-solarized)
  - [x] [CtrlP](https://github.com/ctrlpvim/ctrlp.vim) — fuzzy file finder, buffer switcher, MRU
  - [x] [Snipmate](https://github.com/garbas/vim-snipmate) — [Snippet](https://github.com/honza/vim-snippets) manager for vim
  - [x] [Syntastic](https://github.com/vim-syntastic/syntastic) — syntax checking hacks for vim
  - [ ] [vim-polyglot](https://github.com/sheerun/vim-polyglot) — meta-plugin for syntaxes
  - [x] [vim-rooter](https://github.com/airblade/vim-rooter) — changes working directory to project root
  - [x] [vim-better-whitespace](https://github.com/ntpeters/vim-better-whitespace) — better whitespace highlighting
  - [x] [indentLine](https://github.com/Yggdroot/indentLine) — display the indention levels with thin vertical lines

## [Sublime Text](https://www.sublimetext.com/)

[Package Control](https://packagecontrol.io/) — the first thing to do after the ST installation is to setup the package manager
  - [Installation](https://packagecontrol.io/installation)
  - [Syncing](https://packagecontrol.io/docs/syncing)
```bash
cd ~/Library/Application\ Support/Sublime\ Text\ 3/Packages/
rm -r User
ln -s ~/dotfiles/Library/Application\ Support/Sublime\ Text\ 3/Packages/User/
```
Also take a look awesome [Quick Start Guides](https://github.com/dreikanter/sublime-bookmarks)

## [Automated Workstation Setup](https://github.com/drafael/osx-bootstrap)

`~/dotfiles/bin/bootstrap.sh`

## See Also

* [GitHub does dotfiles](https://dotfiles.github.io/)
* [Awesome Awesomeness](https://github.com/bayandin/awesome-awesomeness)
  - [Dotfiles](https://github.com/webpro/awesome-dotfiles)
  - [Shell](https://github.com/alebcay/awesome-shell)
  - [Dev Env](https://github.com/jondot/awesome-devenv)
  - [Java](https://github.com/akullpp/awesome-java)
* Good looking console emulators for Windows:
  - [cmder](http://cmder.net/)
  - [ConEmu](https://conemu.github.io/)
  - [mintty](http://mintty.github.io/)

## Installation

`git clone git://github.com/drafael/dotfiles.git ~/dotfiles`

## [iTerm2](http://iterm2.com)

Point your preferences to `~/dotfiles/iTerm2/com.googlecode.iterm2.plist`

## Vim or [MacVim](http://macvim-dev.github.io/macvim)

* [Awesome Vim Plugins](http://vimawesome.com/):
  - [x] [Vundle](https://github.com/VundleVim/Vundle.vim) — Plugin manager
  - [x] [Airline](https://github.com/vim-airline/vim-airline) — Status bar
  - [x] [Solarized](https://github.com/altercation/vim-colors-solarized) — Colorscheme
  - [x] [CtrlP](https://github.com/ctrlpvim/ctrlp.vim) — Fuzzy file finder
  - [x] [Snipmate](https://github.com/garbas/vim-snipmate) — [Snippets](https://github.com/honza/vim-snippets) for various programming languages
  - [x] [Syntastic](https://github.com/vim-syntastic/syntastic) — Syntax checking hacks for vim
  - [ ] [vim-polyglot](https://github.com/sheerun/vim-polyglot) — Meta-plugin for syntaxes
* Sync settings and plugins:
```bash
ln -s ~/dotfiles/.vimrc ~/.vimrc
vim +PluginInstall +qall
```

## [Sublime Text](https://www.sublimetext.com/)

* [Package Control](https://packagecontrol.io/) — the first thing to do after the ST installation is to setup the package manager
  - [Installation](https://packagecontrol.io/installation)
  - [Syncing](https://packagecontrol.io/docs/syncing)
* Sync settings and packages:
```bash
cd ~/Library/Application\ Support/Sublime\ Text\ 3/Packages/
rm -r User
ln -s ~/dotfiles/Library/Application\ Support/Sublime\ Text\ 3/Packages/User/
```
* Also take a look awesome [Quick Start Guides](https://github.com/dreikanter/sublime-bookmarks)

## [Automated Workstation Setup](https://github.com/drafael/osx-bootstrap)

`~/dotfiles/bin/bootstrap.sh`

## See Also

* [GitHub does dotfiles](https://dotfiles.github.io/)
* [Awesome Awesomeness](https://github.com/bayandin/awesome-awesomeness)
  - [Dotfiles](https://github.com/webpro/awesome-dotfiles)
  - [Shell](https://github.com/alebcay/awesome-shell)
  - [Dev Env](https://github.com/jondot/awesome-devenv)
  - [Java](https://github.com/akullpp/awesome-java)

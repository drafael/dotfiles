## Prerequisites

* macOS
* Command Line Tools (CLT) for Xcode: `xcode-select --install`, <https://developer.apple.com/downloads> or [Xcode](https://itunes.apple.com/us/app/xcode/id497799835)
* A Bourne-compatible shell for installation (e.g. bash or zsh)

## [Homebrew](http://brew.sh)

```bash
/bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"
```

* [homebrew-services](https://github.com/Homebrew/homebrew-services#homebrew-services) `brew tap homebrew/services`
* [homebrew-cask](https://github.com/Homebrew/homebrew-cask#homebrew-cask) `brew tap homebrew/cask`
* [homebrew-cask-versions](https://github.com/Homebrew/homebrew-cask-versions#homebrew-cask-versions) `brew tap homebrew/cask-versions`

## Vim

* Upgrading

```bash
brew install vim --with-override-system-vi
```

* [MacVim](http://macvim-dev.github.io/macvim) installation

```bash
brew install --cask macvim
```

* Syncing [.vimrc](https://github.com/drafael/dotfiles/blob/master/.vimrc)

```bash
ln -s ~/.dotfiles/.vimrc ~/.vimrc
vim +PluginInstall +qall
```

* [Tagbar](https://github.com/majutsushi/tagbar#tagbar-a-class-outline-viewer-for-vim) dependencies installation

```bash
brew install ctags gotags
ln -s ~/.dotfiles/.ctags ~/.ctags
```

#### My Favorite VIM Plugins

  - [x] [Vundle](https://github.com/VundleVim/Vundle.vim#about) — plugin manager
  - [x] [Airline](https://github.com/vim-airline/vim-airline#vim-airline-) — status bar
  - [x] [vim-colors-solarized](https://github.com/altercation/vim-colors-solarized#screenshots) and [PaperColor Theme](https://github.com/nlknguyen/papercolor-theme#screenshots)
  - [x] [CtrlP](https://github.com/ctrlpvim/ctrlp.vim#ctrlpvim) — fuzzy file finder, buffer switcher, MRU
  - [x] [Auto Pairs](https://github.com/jiangmiao/auto-pairs#auto-pairs) — insert or delete brackets, parens, quotes in pair
  - [x] [Snipmate](https://github.com/garbas/vim-snipmate#snipmate) — [Snippet](https://github.com/honza/vim-snippets#snipmate--ultisnip-snippets) manager for vim
  - [x] [Syntastic](https://github.com/vim-syntastic/syntastic) — syntax checking hacks for vim
  - [x] [Tagbar](https://github.com/majutsushi/tagbar#tagbar-a-class-outline-viewer-for-vim) — plugin that displays tags in a window, ordered by scope
  - [x] [vim-polyglot](https://github.com/sheerun/vim-polyglot#vim-polyglot--) — meta-plugin for syntaxes
  - [x] [vim-rooter](https://github.com/airblade/vim-rooter#rooter) — changes working directory to project root
  - [x] [vim-better-whitespace](https://github.com/ntpeters/vim-better-whitespace#vim-better-whitespace-plugin) — better whitespace highlighting
  - [x] [indentLine](https://github.com/Yggdroot/indentLine#indentline) — display the indention levels with thin vertical lines
  - [x] [vim-session](https://github.com/xolox/vim-session#extended-session-management-for-vim) — extended session management for Vim

![macvim](macvim.png)

#### Also Take a Look

- [Vim Awesome](http://vimawesome.com/)
- [Awesome Vim Color Schemes](https://github.com/rafi/awesome-vim-colorschemes#awesome-vim-color-schemes)
- [Vim Colors](http://vimcolors.com/)
- [SpaceVim](https://spacevim.org/)
- [Tagbar Wiki](https://github.com/majutsushi/tagbar/wiki)

## Command-Line Tools

```bash
brew install ack ag bash-completion editorconfig htop httpie mc ncdu nmap peco ranger tree tig tmux tree
```

* [ack](http://beyondgrep.com) — a code-searching tool like `grep`, optimized for programmers
* [ag](https://github.com/ggreer/the_silver_searcher) — a code searching tool similar to `ack`, with a focus on speed
* [bash-completion](https://github.com/scop/bash-completion) — Programmable completion functions for bash
* [editorconfig](EditorConfig) — helps define and maintain consistent coding styles between different editors and IDEs
* [htop](https://hisham.hm/htop/) — improved top (interactive process viewer)
* [httpie](https://httpie.org/) — is a command line HTTP client
* [mc](https://midnight-commander.org/) — terminal-based visual file manager
* [ncdu](https://dev.yorhel.nl/ncdu) — is a disk usage analyzer with an ncurses interface
* [nmap](https://nmap.org/) — port scanning utility for large networks
* [peco](https://github.com/peco/peco) — simplistic interactive filtering tool
* [ranger](https://ranger.github.io/) — a console file manager with `vi` key bindings
* [tree](http://mama.indstate.edu/users/ice/tree/) — recursive directory listing command that produces a depth indented listing of files
* [tig](http://jonas.nitro.dk/tig/) — ncurses-based text-mode interface for `git`
* [tmux](http://tmux.github.io) — a terminal multiplexer
* [tree](http://mama.indstate.edu/users/ice/tree/) — display directories as trees

## Java Dev Env

* Install Java `brew install java11`
* Build tools `brew install ant maven gradle`
* [IntelliJ IDEA](https://www.jetbrains.com/idea/)
  - Community `brew install intellij-idea-ce`
  - Ultimate `brew install intellij-idea`

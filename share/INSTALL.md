## Requirements
* macOS
* Command Line Tools (CLT) for Xcode: `xcode-select --install`, https://developer.apple.com/downloads or [Xcode](https://itunes.apple.com/us/app/xcode/id497799835)
* A Bourne-compatible shell for installation (e.g. bash or zsh)

## [Homebrew](http://brew.sh)
```bash
/usr/bin/ruby -e "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/master/install)"
```
* [homebrew-versions](https://github.com/Homebrew/homebrew-versions#homebrew-versions) `brew tap homebrew/versions`
* [homebrew-services](https://github.com/Homebrew/homebrew-services#homebrew-services) `brew tap homebrew/services`
* [homebrew-cask](https://github.com/caskroom/homebrew-cask#homebrew-cask) `brew tap caskroom/cask`
* [homebrew-cask-versions](https://github.com/caskroom/homebrew-versions#homebrew-cask-versions) `brew tap caskroom/versions`

## Vim
* Upgrading
```bash
brew install vim --with-override-system-vi
```
* [MacVim](http://macvim-dev.github.io/macvim) installation
```bash
brew cask install macvim
```
* Syncing [.vimrc](https://github.com/drafael/dotfiles/blob/master/.vimrc)
```bash
ln -s ~/dotfiles/.vimrc ~/.vimrc
vim +PluginInstall +qall
```
#### Vim plugins that I like and/or use regularly
- [x] [Vundle](https://github.com/VundleVim/Vundle.vim#about) - plugin manager
- [x] [Airline](https://github.com/vim-airline/vim-airline#vim-airline-) - status bar
- [x] [vim-colors-solarized](https://github.com/altercation/vim-colors-solarized#screenshots)
- [x] [CtrlP](https://github.com/ctrlpvim/ctrlp.vim#ctrlpvim) - fuzzy file finder, buffer switcher, MRU
- [x] [Snipmate](https://github.com/garbas/vim-snipmate#snipmate) - [Snippet](https://github.com/honza/vim-snippets#snipmate--ultisnip-snippets) manager for vim
- [x] [Syntastic](https://github.com/vim-syntastic/syntastic) - syntax checking hacks for vim
- [x] [vim-polyglot](https://github.com/sheerun/vim-polyglot#vim-polyglot--) - meta-plugin for syntaxes
- [x] [vim-rooter](https://github.com/airblade/vim-rooter#rooter) - changes working directory to project root
- [x] [vim-better-whitespace](https://github.com/ntpeters/vim-better-whitespace#vim-better-whitespace-plugin) - better whitespace highlighting
- [x] [indentLine](https://github.com/Yggdroot/indentLine#indentline) - display the indention levels with thin vertical lines

![macvim](https://github.com/drafael/dotfiles/raw/master/share/macvim.png)

#### Also
- [Vim Awesome](http://vimawesome.com/)
- [Vim Colors](http://vimcolors.com/)

## Command-Line Tools
```bash
brew install ack ag peco tree tig tmux
```
* [ack](http://beyondgrep.com) - a code-searching tool like `grep`, optimized for programmers
* [ag](https://github.com/ggreer/the_silver_searcher) - a code searching tool similar to `ack`, with a focus on speed
* [peco](https://github.com/peco/peco) - simplistic interactive filtering tool
* [tree](http://mama.indstate.edu/users/ice/tree/) - recursive directory listing command that produces a depth indented listing of files
* [tig](http://jonas.nitro.dk/tig/) - ncurses-based text-mode interface for `git`
* [tmux](http://tmux.github.io) - a terminal multiplexer

## Java Dev Env
* JDK `brew cask install java`
* Build tools `brew install ant maven gradle`
* [IntelliJ IDEA](https://www.jetbrains.com/idea/)
  - Community `brew cask install intellij-idea-ce`
  - Ultimate `brew cask install intellij-idea`
  - EAP `brew cask install intellij-idea-eap`
* [Spring Boot](http://docs.spring.io/spring-boot/docs/current/reference/htmlsingle/) `brew tap pivotal/tap; brew install springboot`


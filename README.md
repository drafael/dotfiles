## Installation

`$ git clone git://github.com/drafael/dotfiles.git ~/.dotfiles`

## VIM

```
$ ln -s ~/.dotfiles/vim ~/.vim
$ ln -s ~/.dotfiles/vim/vimrc ~/.vimrc
$ ln -s ~/.dotfiles/vim/vimrc ~/.gvimrc
```

## [MacVim](https://code.google.com/p/macvim/)

1.  Install [Homebrew](http://brew.sh)

2.  Install MacVim
    ```
    $ brew install macvim
    $ brew linkapps
    ```

There’s also a experimental branch which adds a file-browser side pane:

3.  Install [MacVim with file browser](https://github.com/joelcogen/homebrew-macvimsplitbrowser)
    ```
    $ brew tap joelcogen/macvimsplitbrowser
    $ brew install macvim-split-browser
    $ brew linkapps
    ```

## [iTerm2](http://iterm2.com)

Point your preferences to `~/.dotfiles/iTerm2/com.googlecode.iterm2.plist`

or copy prefernces file:
`cp ~/.dotfiles/iTerm2/com.googlecode.iterm2.plist ~/Library/Preferences`

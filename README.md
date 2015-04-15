## Installation

`$ git clone git://github.com/drafael/dotfiles.git ~/.dotfiles`

## Vim

```
$ ln -s ~/.dotfiles/vimrc ~/.vimrc
$ ln -s ~/.dotfiles/vimrc ~/.gvimrc
```

## [MacVim](https://code.google.com/p/macvim/)

1.  Install [Homebrew](http://brew.sh).

2.  Install [MacVim](https://code.google.com/p/macvim/):

    ```
    $ brew install macvim
    $ brew linkapps
    ```

    or [MacVim with file browser](https://github.com/joelcogen/homebrew-macvimsplitbrowser):

    ```
    $ brew tap joelcogen/macvimsplitbrowser
    $ brew install macvim-split-browser
    $ brew linkapps
    ```

3.  [Use Caps Lock as Esc](http://stackoverflow.com/questions/127591/using-caps-lock-as-esc-in-mac-os-x)


## [iTerm2](http://iterm2.com)

Point your preferences to `~/.dotfiles/iTerm2/com.googlecode.iterm2.plist`


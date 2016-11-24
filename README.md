## Installation

`git clone git://github.com/drafael/dotfiles.git ~/dotfiles`

## Vim

```
ln -s ~/dotfiles/.vimrc ~/.vimrc
vim +PluginInstall +qall
```

## [iTerm2](http://iterm2.com)

Point your preferences to `~/dotfiles/iTerm2/com.googlecode.iterm2.plist`

## [Sublime Text](https://www.sublimetext.com/)

* RTFM [Package Control: Manual installation](https://packagecontrol.io/installation)
* RTFM [Package Control: Syncing](https://packagecontrol.io/docs/syncing)

```
cd ~/Library/Application\ Support/Sublime\ Text\ 3/
rm -r Installed\ Packages/
ln -s ~/dotfiles/Library/Application\ Support/Sublime\ Text\ 3/Installed\ Packages/

cd ~/Library/Application\ Support/Sublime\ Text\ 3/Packages/
rm -r User
ln -s ~/dotfiles/Library/Application\ Support/Sublime\ Text\ 3/Packages/User/
```
* Open Sublime Text `open /Applications/Sublime\ Text.app/`
* Ignore errors and wait
* Quit and open again

## [Automated Workstation Setup](https://github.com/drafael/osx-bootstrap)

`~/dotfiles/osx-bootstrap.sh`

## See Also

* [GitHub does dotfiles](https://dotfiles.github.io/)
* [Awesome Awesomeness](https://github.com/bayandin/awesome-awesomeness)

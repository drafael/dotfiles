#!/usr/bin/env bash

dotfiles=$(dirname "$0")

# if [ ! -x "$(command -v git)" ]; then
#   xcode-select --install
# fi

if [ ! -x "$(command -v brew)" ]; then
  echo "brew..."
  ruby -e "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/master/install)"

  echo "taps..."
  brew tap homebrew/bundle
  brew tap homebrew/versions
  brew tap homebrew/services
  brew tap caskroom/cask
  brew tap caskroom/versions

  echo "cli tools..."
  brew install ack ag bash-completion htop mc nmap peco ranger ssh-copy-id tree tig tmux tree wget
else
  echo "brew...    OK"
fi

if brew ls --versions vim > /dev/null; then
  echo "vim...     OK"
else
  echo "vim..."
  brew install vim --with-override-system-vi
fi

if [ -d "$HOME/.vim" ]; then
  echo ".vimrc...  OK"
else
  echo ".vimrc..."
  ln -s "$dotfiles/.vimrc" "$HOME/.vimrc"
  vim +PluginInstall +qall
fi

if [ ! -x "$(command -v mvim)" ]; then
  echo "MacVim..."
  brew cask install macvim
else
  echo "MacVim...  OK"
fi

if [ ! -x "$(command -v subl)" ]; then
  echo "Sublime..."
  brew cask install sublime-text
  # Package Control
  mkdir -p "$HOME/Library/Application Support/Sublime Text 3"
  rm -r "$HOME/Library/Application Support/Sublime Text 3/Installed Packages"
  ln -s "$dotfiles/Library/Application Support/Sublime Text 3/Installed Packages" "$HOME/Library/Application Support/Sublime Text 3/Installed Packages"
  # Syncing
  mkdir -p "$HOME/Library/Application Support/Sublime Text 3/Packages"
  rm -r "$HOME/Library/Application Support/Sublime Text 3/Packages/User"
  ln -s "$dotfiles/Library/Application Support/Sublime Text 3/Packages/User" "$HOME/Library/Application Support/Sublime Text 3/Packages/User"
else
  echo "Sublime... OK"
fi

if [ ! -x "$(command -v mas)" ]; then
  echo "mas..."
  brew install mas

  echo "1Password..."
  mas install 443987910
else
  echo "mas...     OK"
fi

if [ ! -x "$(command -v ansible)" ]; then
  brew install ansible
else
  echo "ansible... OK"
fi

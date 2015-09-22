#!/usr/bin/env bash

if test ! $(which brew); then
  echo "Installing homebrew..."
  sudo -v
  ruby -e "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/master/install)"
fi

brew update

# init homebrew
brew tap homebrew/bundle
brew tap homebrew/versions

# init cask
brew tap caskroom/cask
brew install caskroom/cask/brew-cask
brew tap caskroom/versions

# Install command-line tools
brew bundle Brewfile
brew linkapps
brew cleanup

# Install OSX apps
brew bundle Caskfile
brew cask cleanup

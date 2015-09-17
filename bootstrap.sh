#!/usr/bin/env bash

# Install Homebrew
/usr/bin/ruby -e "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/master/install)"

# Install command-line tools
brew tap Homebrew/bundle
brew bundle Brewfile

# Install OSX apps
brew install caskroom/cask/brew-cask
brew bundle Caskfile

brew cleanup
brew cask cleanup

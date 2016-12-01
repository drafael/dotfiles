#!/usr/bin/env bash

if test ! $(which git); then
  xcode-select --install
fi

if test ! $(which brew); then
  ruby -e "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/master/install)"
fi

if test ! $(which ansible); then
  brew install ansible
fi

if [ ! -d ~/code ]; then
  mkdir ~/code
fi

cd ~/code

if [ ! -d ~/code/osx-bootstrap ]; then
  git clone https://github.com/drafael/osx-bootstrap.git
fi

cd ~/code/osx-bootstrap

export HOMEBREW_CASK_OPTS="--appdir=/Applications"

ansible-playbook site.yml

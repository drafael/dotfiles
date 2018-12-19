#!/usr/bin/env bash

dotfiles="$( cd "$( dirname "${BASH_SOURCE[0]}" )" >/dev/null && pwd )"

echo "================================================="
echo "  dotfiles dir: $dotfiles"
echo "================================================="

echo "Bash..."
set -x
ln -sfn "$dotfiles/.bash_profile" "$HOME/.bash_profile"
ln -sfn "$dotfiles/.bashrc" "$HOME/.bashrc"
set +x
source "$HOME/.bashrc"

echo "Git..."
if [ ! -x "$(command -v git)" ]; then
  set -x
  if [ ! -x "$(command -v xcode-select)" ]; then
    echo "Please install the Xcode or CLT"
    exit 1
  else
    xcode-select --install
  fi
  set +x
else
  echo "Git... OK"
fi

if [ ! -x "$(command -v brew)" ]; then
  echo "brew..."
  ruby -e "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/master/install)"

  echo "taps..."
  set -x
  brew tap homebrew/bundle
  brew tap homebrew/versions
  brew tap homebrew/services
  brew tap homebrew/cask
  brew tap homebrew/cask-versions
  set +x
else
  echo "brew...      OK"
fi

for pkg in ack ag bash-completion htop mc ncdu nmap peco ranger ssh-copy-id tree tig tmux tree wget; do
  if [ ! -x "$(command -v $pkg)" ]; then
    echo "$pkg..."
    brew install $pkg
  else
    echo "$pkg... OK"
  fi
done

if brew cask ls --versions iterm2 &> /dev/null; then
  echo "iTerm2...    OK"
else
  echo "iTerm2..."
  # brew cask install iterm2
  # open "$dotfiles/iTerm2/colors/Solarized Dark.itermcolors"
  # open "$dotfiles/iTerm2/colors/Solarized Light.itermcolors"
  # open "$dotfiles/iTerm2/colors/papercolor-light.itermcolors"
fi

if brew ls --versions vim &> /dev/null; then
  echo "vim...       OK"
else
  echo "vim..."
  set -x
  brew install vim --with-override-system-vi
  brew install ctags
  ln -sfn "$dotfiles/.ctags" "$HOME/.ctags"
  set +x
fi

if [ -d "$HOME/.vim" ]; then
  echo ".vimrc...    OK"
else
  echo ".vimrc..."
  set -x
  ln -sfn "$dotfiles/.vimrc" "$HOME/.vimrc"
  vim +PluginInstall +qall
  set +x
fi

if [ ! -x "$(command -v mvim)" ]; then
  echo "MacVim..."
  brew cask install macvim
else
  echo "MacVim...    OK"
fi

if [ ! -x "$(command -v subl)" ]; then
  echo "Sublime Text..."
  set -x
  brew cask install sublime-text
  # Package Control
  mkdir -p "$HOME/Library/Application Support/Sublime Text 3"
  rm -r "$HOME/Library/Application Support/Sublime Text 3/Installed Packages"
  ln -s "$dotfiles/Library/Application Support/Sublime Text 3/Installed Packages" "$HOME/Library/Application Support/Sublime Text 3/Installed Packages"
  # Syncing
  mkdir -p "$HOME/Library/Application Support/Sublime Text 3/Packages"
  rm -r "$HOME/Library/Application Support/Sublime Text 3/Packages/User"
  ln -s "$dotfiles/Library/Application Support/Sublime Text 3/Packages/User" "$HOME/Library/Application Support/Sublime Text 3/Packages/User"
  set +x
else
  echo "Sublime Text...   OK"
fi

if [ ! -x "$(command -v smerge)" ]; then
  echo "Sublime Merge..."
  brew cask install sublime-merge
else
  echo "Sublime Merge...   OK"
fi

if [ ! -x "$(command -v docker)" ]; then
  echo "Docker..."
  brew cask install docker
  brew install docker-clean
else
  echo "Docker...    OK"
fi

# if [ ! -x "$(command -v java)" ]; then
#   echo "Java..."
#   set -x
#   brew cask install java8
#   # brew cask install java
#   brew install ant maven gradle
#   set +x
# else
#   echo "Java...      OK"
# fi

# if brew cask ls --versions intellij-idea &> /dev/null; then
#   echo "Intellij IDEA...   OK"
# else
#   echo "Intellij IDEA..."
#   brew cask install intellij-idea
# fi

# if brew cask ls --versions pycharm &> /dev/null; then
#   echo "PyCharm...   OK"
# else
#   echo "PyCharm..."
#   brew cask install pycharm
# fi

# if brew cask ls --versions datagrip &> /dev/null; then
#   echo "DataGrip...   OK"
# else
#   echo "DataGrip..."
#   brew cask install datagrip
# fi

if brew cask ls --versions firefox &> /dev/null; then
  echo "Firefox...   OK"
else
  echo "Firefox..."
  brew cask install firefox
fi

if brew cask ls --versions google-chrome &> /dev/null; then
  echo "Google Chrome...   OK"
else
  echo "Google Chrome..."
  brew cask install google-chrome
fi

if brew cask ls --versions tunnelblick &> /dev/null; then
  echo "OpenVPN...   OK"
else
  echo "OpenVPN..."
  brew cask install tunnelblick
fi

# if [ ! -x "$(command -v ansible)" ]; then
#   echo "Ansible..."
#   brew install ansible
# else
#   echo "Ansible...   OK"
# fi

if [ ! -x "$(command -v mas)" ]; then
  echo "mas..."
  brew install mas
else
  echo "mas...       OK"
fi

echo "1Password...";            mas install 443987910
echo "Keka...";                 mas install 470158793
echo "Lightshot Screenshot..."; mas install 526298438
echo "Adblock Plus...";         mas install 1432731683
echo "Murasaki...";             mas install 430300762
echo "DjVu Reader...";          mas install 733144595
echo "VSD Viewer...";           mas install 580788158
echo "Xee³...";                 mas install 639764244
echo "Keynote...";              mas install 409183694
echo "Numbers...";              mas install 409203825
echo "Pages...";                mas install 409201541

brew cleanup
# EOF

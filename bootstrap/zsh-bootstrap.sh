#!/usr/bin/env zsh

dotfiles="$( cd "$( dirname "${(%):-%N}" )" >/dev/null && pwd )"

echo "================================================="
echo "  dotfiles dir: $dotfiles"
echo "================================================="

echo "zsh..."
set -x
ln -sfn "$dotfiles/.zshrc" "$HOME/.zshrc"
set +x
source "$HOME/.zshrc"

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
  /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"

  echo "taps..."
  set -x
  brew tap homebrew/bundle
  brew tap homebrew/services
  brew tap homebrew/cask-versions
  set +x
else
  echo "brew...      OK"
fi

for pkg in ack ag gcc htop mc ncdu neovim nmap peco pt ranger ripgrep ssh-copy-id tree tig tmux tree wget; do
  if [ ! -x "$(command -v $pkg)" ]; then
    echo "$pkg..."
    brew install $pkg
  else
    echo "$pkg... OK"
  fi
done

if brew ls --cask --versions iterm2 &> /dev/null; then
  echo "iTerm2...    OK"
else
  echo "iTerm2..."
  brew install iterm2
  # open "$dotfiles/iTerm2/colors/Solarized Dark.itermcolors"
  # open "$dotfiles/iTerm2/colors/Solarized Light.itermcolors"
  # open "$dotfiles/iTerm2/colors/papercolor-light.itermcolors"
fi

if [ ! -x "$(command -v mas)" ]; then
  echo "mas..."
  brew install mas
else
  echo "mas...       OK"
fi

echo "1Password...";            mas install 443987910
echo "Keka...";                 mas install 470158793
echo "Adblock Plus...";         mas install 1432731683
echo "Murasaki...";             mas install 430300762
echo "DjVu Reader...";          mas install 733144595
echo "VSD Viewer...";           mas install 580788158

if brew cask ls --versions appcleaner &> /dev/null; then
  echo "AppCleaner...   OK"
else
  echo "AppCleaner..."
  brew install --cask appcleaner
fi

if brew ls --cask --versions firefox &> /dev/null; then
  echo "Firefox...   OK"
else
  echo "Firefox..."
  brew install --cask firefox
fi

if brew ls --cask --versions google-chrome &> /dev/null; then
  echo "Google Chrome...   OK"
else
  echo "Google Chrome..."
  brew install --cask google-chrome
fi

if brew ls --cask --versions dropbox &> /dev/null; then
  echo "Dropbox...   OK"
else
  echo "Dropbox..."
  brew install --cask dropbox
fi

if brew ls --cask --versions tunnelblick &> /dev/null; then
  echo "OpenVPN...   OK"
else
  echo "OpenVPN..."
  brew install --cask tunnelblick
fi

if [ ! -x "$(command -v docker)" ]; then
  echo "Docker..."
  brew install --cask docker
else
  echo "Docker...    OK"
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
  brew install --cask macvim
else
  echo "MacVim...    OK"
fi

if [ ! -x "$(command -v subl)" ]; then
  echo "Sublime Text..."
  set -x
  brew install sublime-text
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
  brew install sublime-merge
else
  echo "Sublime Merge...   OK"
fi

if [ ! -x "$(command -v java)" ]; then
  echo "Java..."
  set -x
  brew install java11
  brew install ant maven gradle
  set +x
else
  echo "Java...      OK"
fi

if brew ls --cask --versions intellij-idea &> /dev/null; then
  echo "Intellij IDEA...   OK"
else
  echo "Intellij IDEA..."
  brew install intellij-idea
fi

if brew ls --cask --versions pycharm &> /dev/null; then
  echo "PyCharm...   OK"
else
  echo "PyCharm..."
  brew install pycharm
fi

# if brew ls --cask --versions datagrip &> /dev/null; then
#   echo "DataGrip...   OK"
# else
#   echo "DataGrip..."
#   brew install datagrip
# fi

# if brew ls --cask --versions microsoft-office &> /dev/null; then
#   echo "Microsoft Office...   OK"
# else
#   echo "Microsoft Office..."
#   brew install microsoft-office
# fi

if brew ls --cask --versions microsoft-teams &> /dev/null; then
  echo "Microsoft Teams...   OK"
else
  echo "Microsoft Teams..."
  brew install microsoft-teams
fi

# echo "Keynote...";      mas install 409183694
# echo "Numbers...";      mas install 409203825
# echo "Pages...";        mas install 409201541
# echo "Aperture...";     mas install 408981426

brew cleanup
# EOF

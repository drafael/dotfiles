#!/usr/bin/env zsh

# softwareupdate --install-rosetta --agree-to-license

dotfiles="$HOME/.dotfiles"

echo "================================================="
echo "  dotfiles dir: $dotfiles"
echo "================================================="

echo "zsh..."
ln -sfn "$dotfiles/.zshrc" "$HOME/.zshrc"
source "$HOME/.zshrc"


if [ ! -x "$(command -v brew)" ]; then
  echo "brew..."
  /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"
else
  echo "brew...      OK"
fi

for pkg in ack ag htop mc ncdu neovim nmap peco pt ranger ripgrep ssh-copy-id tree tig tmux tree wget; do
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

if brew ls --cask --versions ghostty &> /dev/null; then
  echo "Ghostty...    OK"
else
  echo "Ghostty..."
  brew install --cask ghostty
  mkdir -p $HOME/.config/ghostty && ln -sfn $HOME/.dotfiles/.config/ghostty/config $HOME/.config/ghostty/config
fi

if brew cask ls --versions appcleaner &> /dev/null; then
  echo "AppCleaner...   OK"
else
  echo "AppCleaner..."
  brew install --cask appcleaner
fi

if brew ls --cask --versions google-chrome &> /dev/null; then
  echo "Google Chrome...   OK"
else
  echo "Google Chrome..."
  brew install --cask google-chrome
fi

if brew ls --cask --versions tunnelblick &> /dev/null; then
  echo "OpenVPN...   OK"
else
  echo "OpenVPN..."
  brew install --cask tunnelblick
fi

if [ ! -x "$(command -v docker)" ]; then
  echo "Docker..."
  brew install docker docker-compose kubectl helm colima podman minikube
else
  echo "Docker...    OK"
fi

if brew ls --versions vim &> /dev/null; then
  echo "vim...       OK"
else
  echo "vim..."
  brew install vim
  brew install ctags
  ln -sfn "$dotfiles/.ctags" "$HOME/.ctags"
fi

if [ -d "$HOME/.vim" ]; then
  echo ".vimrc...    OK"
else
  echo ".vimrc..."
  ln -sfn "$dotfiles/.vimrc" "$HOME/.vimrc"
  vim +PluginInstall +qall
fi

if [ ! -x "$(command -v zed)" ]; then
  echo "Zed..."
  brew install --cask zed
else
  echo "Zed...    OK"
fi

if [ ! -x "$(command -v code)" ]; then
  echo "Visual Studio Code..."
  brew install --cask visual-studio-code
else
  echo "Visual Studio Code...    OK"
fi

if [ ! -x "$(command -v java)" ]; then
  echo "Java..."
  brew install openjdk@11 openjdk@21
  sudo ln -sfn $(brew --prefix)/opt/openjdk@11/libexec/openjdk.jdk /Library/Java/JavaVirtualMachines/openjdk-11.jdk
  sudo ln -sfn $(brew --prefix)/opt/openjdk@21/libexec/openjdk.jdk /Library/Java/JavaVirtualMachines/openjdk-21.jdk
  brew install ant maven gradle
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

if brew ls --cask --versions datagrip &> /dev/null; then
  echo "DataGrip...   OK"
else
  echo "DataGrip..."
  brew install datagrip
fi

# if brew ls --cask --versions microsoft-office &> /dev/null; then
#   echo "Microsoft Office...   OK"
# else
#   echo "Microsoft Office..."
#   brew install microsoft-office
# fi

# if brew ls --cask --versions microsoft-teams &> /dev/null; then
#   echo "Microsoft Teams...   OK"
# else
#   echo "Microsoft Teams..."
#   brew install microsoft-teams
# fi

brew cleanup
# EOF

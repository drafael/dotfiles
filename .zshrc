#!/usr/bin/env zsh

if [[ -z "$DOTFILES_DIR" ]]; then
  if [[ -d "$HOME/.dotfiles" ]]; then
    export DOTFILES_DIR="$HOME/.dotfiles"
  elif [[ -d "$HOME/dotfiles" ]]; then
    export DOTFILES_DIR="$HOME/dotfiles"
  else
    export DOTFILES_DIR="$HOME"
  fi
fi

if [ -f "$DOTFILES_DIR/env.sh" ]; then
  source "$DOTFILES_DIR/env.sh"
fi

if [ -f "$DOTFILES_DIR/aliases.sh" ]; then
  source "$DOTFILES_DIR/aliases.sh"
fi

if [[ $OSTYPE =~ darwin ]]; then
  if [ -f "$DOTFILES_DIR/darwin.sh" ]; then
    source "$DOTFILES_DIR/darwin.sh"
  fi
elif [[ $OSTYPE =~ linux ]]; then
  if [ -f "$DOTFILES_DIR/linux.sh" ]; then
    source "$DOTFILES_DIR/linux.sh"
  fi
fi

if [ -f "$HOME/.zshrc.local" ]; then
  source "$HOME/.zshrc.local"
fi

if command -v starship &>/dev/null; then
  export STARSHIP_CONFIG="$DOTFILES_DIR/.config/starship.toml"
  eval "$(starship init zsh)"
else
  fpath+=("$DOTFILES_DIR/zsh-prompt")
  autoload -U promptinit; promptinit
  zstyle :prompt:pure:git:branch color green
  zstyle :prompt:pure:git:action color green
  zstyle :prompt:pure:prompt:error color red
  zstyle :prompt:pure:prompt:success color green
  prompt pure
fi

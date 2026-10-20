#!/bin/sh

# Package identities, not installation history. Bootstrap and update.sh share
# these lists; optional groups are selected for updates only when installed.
bootstrap_packages() {
  package_platform=$1
  package_manager=$2
  package_group=$3
  if [ "$package_group" = all ]; then
    for catalog_group in cli prerequisites javascript java fonts terminal editors docker podman onepassword agents extras; do
      bootstrap_packages "$package_platform" "$package_manager" "$catalog_group"
    done | sort -u
    return
  fi

  package_list=''
  case "$package_platform:$package_manager:$package_group" in
    macos:brew-formula:cli)
      package_list='git git-lfs gh glab starship tmux fzf fd zoxide ripgrep btop htop lazygit tig midnight-commander yazi kooler/apps/middaycommander jq tree wget sevenzip poppler resvg' ;;
    macos:brew-formula:javascript) package_list='node bun' ;;
    macos:brew-formula:java) package_list='openjdk@25 maven gradle' ;;
    macos:brew-formula:terminal) package_list='neovim' ;;
    macos:brew-formula:docker) package_list='colima docker docker-compose docker-buildx kubernetes-cli helm minikube' ;;
    macos:brew-formula:podman) package_list='podman podman-compose kubernetes-cli helm minikube' ;;
    macos:brew-formula:extras) package_list='ffmpeg-full imagemagick-full mise umputun/apps/revdiff' ;;
    macos:brew-cask:fonts)
      package_list='font-cascadia-code font-fira-code font-fira-code-nerd-font font-hack font-jetbrains-mono font-source-code-pro font-symbols-only-nerd-font' ;;
    macos:brew-cask:terminal) package_list='ghostty' ;;
    macos:brew-cask:editors) package_list='intellij-idea visual-studio-code cursor zed' ;;
    macos:brew-cask:onepassword) package_list='1password 1password-cli' ;;
    # Recognize package-manager installations of agents too, although bootstrap
    # uses their native installers (and npm for Codex) when they are missing.
    macos:brew-formula:agents) package_list='opencode pi-coding-agent' ;;
    macos:brew-cask:agents) package_list='claude-code codex' ;;
    ubuntu:system:prerequisites) package_list='software-properties-common curl ca-certificates xz-utils python3 snapd' ;;
    ubuntu:system:cli)
      package_list='git git-lfs gh zsh tmux fzf fd-find zoxide ripgrep wl-clipboard build-essential unzip btop htop tig mc jq tree wget file ffmpeg 7zip poppler-utils imagemagick' ;;
    ubuntu:system:java) package_list='openjdk-25-jdk maven' ;;
    ubuntu:system:fonts) package_list='ca-certificates curl fontconfig fonts-cascadia-code fonts-firacode fonts-hack fonts-jetbrains-mono jq unzip xz-utils' ;;
    ubuntu:system:terminal) package_list='curl ca-certificates xz-utils python3 kitty' ;;
    ubuntu:system:docker) package_list='docker.io docker-compose-v2 docker-buildx' ;;
    ubuntu:system:podman) package_list='podman podman-compose' ;;
    ubuntu:system:onepassword) package_list='1password 1password-cli' ;;
    ubuntu:system:extras) package_list='yazi resvg gnupg' ;;
    fedora:system:cli)
      package_list='git git-lfs gh glab curl ca-certificates zsh util-linux tmux fzf fd-find zoxide ripgrep wl-clipboard gcc gcc-c++ make unzip btop htop tig mc jq tree file 7zip poppler-utils ImageMagick' ;;
    fedora:system:java) package_list='java-25-openjdk-devel maven' ;;
    fedora:system:fonts) package_list='adobe-source-code-pro-fonts cascadia-code-fonts fira-code-fonts fontconfig jetbrains-mono-fonts source-foundry-hack-fonts curl jq tar xz unzip' ;;
    fedora:system:terminal) package_list='neovim kitty' ;;
    fedora:system:docker) package_list='moby-engine docker-compose docker-buildx' ;;
    fedora:system:podman) package_list='podman podman-compose' ;;
    fedora:system:onepassword) package_list='1password 1password-cli' ;;
    fedora:system:extras) package_list='wget1-wget ffmpeg-free gnupg2 tar' ;;
    arch:system:cli)
      package_list='git git-lfs github-cli glab curl zsh starship tmux fzf fd zoxide ripgrep wl-clipboard base-devel unzip btop htop lazygit tig mc yazi jq tree wget file ffmpeg 7zip poppler resvg imagemagick' ;;
    omarchy:system:cli)
      package_list='git git-lfs glab tmux fzf fd zoxide ripgrep starship wl-clipboard base-devel unzip btop htop lazygit tig mc yazi jq tree wget file ffmpeg 7zip poppler resvg imagemagick' ;;
    arch:system:java|omarchy:system:java) package_list='jdk25-openjdk maven gradle' ;;
    arch:system:fonts|omarchy:system:fonts)
      package_list='adobe-source-code-pro-fonts fontconfig ttf-cascadia-code ttf-fira-code ttf-firacode-nerd ttf-hack ttf-jetbrains-mono ttf-nerd-fonts-symbols ttf-nerd-fonts-symbols-mono' ;;
    arch:system:terminal) package_list='neovim ghostty' ;;
    omarchy:system:terminal) package_list='nvim' ;;
    arch:system:docker|omarchy:system:docker) package_list='docker docker-compose docker-buildx kubectl helm minikube' ;;
    arch:system:podman|omarchy:system:podman) package_list='podman podman-compose kubectl helm minikube' ;;
    arch:system:extras) package_list='mise ca-certificates gnupg jq unzip' ;;
    omarchy:system:extras) package_list='mise-bin 1password 1password-cli ca-certificates curl gnupg jq unzip' ;;
    *:npm:javascript) package_list='typescript typescript-language-server tsx' ;;
    *:npm:agents) package_list='@openai/codex @earendil-works/pi-coding-agent @badlogic/pi-coding-agent @anthropic-ai/claude-code opencode-ai' ;;
    *:mise:javascript) package_list='node bun' ;;
    *:mise:agents) package_list='claude codex opencode pi' ;;
    omarchy:mise:extras) package_list='gh' ;;
  esac
  printf '%s\n' "$package_list" | tr ' ' '\n' | awk 'NF'
}

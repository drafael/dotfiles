#!/bin/sh

set -eu

BOOTSTRAP_DIR=$(CDPATH= cd -- "$(dirname -- "$0")" && pwd)
# shellcheck source=lib.sh
. "$BOOTSTRAP_DIR/lib.sh"

HARNESS_DIR="$HOME/code/harness"

usage() {
  printf '%s\n' \
    'Usage: verify.sh' \
    '' \
    'Print installed tool versions without changing the workstation.'
}

print_command_version() {
  command_name=$1
  if ! command -v "$command_name" >/dev/null 2>&1; then
    warn "$command_name is not available"
    return
  fi

  case $command_name in
    git) first_line git --version ;;
    git-lfs) first_line git lfs version ;;
    gh)
      if [ "$PLATFORM" = omarchy ]; then
        printf 'gh: Omarchy lazy launcher available\n'
      else
        first_line gh --version
      fi
      ;;
    glab) first_line glab --version ;;
    mise) first_line mise --version ;;
    node) first_line node --version ;;
    npm) first_line npm --version ;;
    bun) first_line bun --version ;;
    tsc) first_line tsc --version ;;
    typescript-language-server) first_line typescript-language-server --version ;;
    tsx) first_line tsx --version ;;
    tmux) first_line tmux -V ;;
    nvim) first_line nvim --version ;;
    btop) first_line btop --version ;;
    htop) first_line htop --version ;;
    lazygit) first_line lazygit --version ;;
    tig) first_line tig --version ;;
    mc) first_line mc --version ;;
    yazi) first_line yazi --version ;;
    mdc) first_line mdc --version ;;
    jq) first_line jq --version ;;
    tree) first_line tree --version ;;
    wget) first_line wget --version ;;
    fzf) first_line fzf --version ;;
    fd) first_line fd --version ;;
    zoxide) first_line zoxide --version ;;
    rg) first_line rg --version ;;
    revdiff) first_line revdiff --version ;;
    java) first_line java -version ;;
    javac) first_line javac -version ;;
    mvn) first_line mvn -version ;;
    gradle) first_line gradle --version ;;
  esac
}

dependency_state() {
  for dependency_command in "$@"; do
    if command -v "$dependency_command" >/dev/null 2>&1; then
      printf 'ok'
      return
    fi
  done
  printf 'missing'
}

font_family_state() {
  verified_family=$1
  if ! command -v fc-list >/dev/null 2>&1; then
    printf 'unknown'
  elif fc-list : family 2>/dev/null | grep -Fq "$verified_family"; then
    printf 'ok'
  else
    printf 'missing'
  fi
}

print_font_support() {
  printf 'Font support: jetbrains-mono=%s cascadia-code=%s source-code-pro=%s hack=%s nerd-symbols-mono=%s\n' \
    "$(font_family_state 'JetBrains Mono')" \
    "$(font_family_state 'Cascadia Code')" \
    "$(font_family_state 'Source Code Pro')" \
    "$(font_family_state Hack)" \
    "$(font_family_state 'Symbols Nerd Font Mono')"
}

print_yazi_support() {
  file_state=$(dependency_state file)
  printf 'Yazi support: file=%s ffmpeg=%s 7zip=%s poppler=%s resvg=%s imagemagick=%s fd=%s rg=%s fzf=%s zoxide=%s\n' \
    "$file_state" \
    "$(dependency_state ffmpeg)" \
    "$(dependency_state 7zz 7z)" \
    "$(dependency_state pdftotext)" \
    "$(dependency_state resvg)" \
    "$(dependency_state magick convert)" \
    "$(dependency_state fd)" \
    "$(dependency_state rg)" \
    "$(dependency_state fzf)" \
    "$(dependency_state zoxide)"
  if [ "$file_state" = missing ]; then
    warn 'file is required for Yazi file type detection'
  fi
}

verify_harness_link() {
  harness_link_source=$1
  harness_link_destination=$2
  if symlink_points_to_path "$harness_link_destination" "$harness_link_source"; then
    printf 'harness link: %s\n' "$harness_link_destination"
  else
    warn "$harness_link_destination does not link to $harness_link_source"
  fi
}

print_harness_status() {
  if [ -d "$HARNESS_DIR/.git" ] && command -v git >/dev/null 2>&1; then
    harness_origin=$(git -C "$HARNESS_DIR" remote get-url origin 2>/dev/null || printf 'unknown')
    printf 'coding harness: %s (%s)\n' "$HARNESS_DIR" "$harness_origin"
  elif [ -d "$HARNESS_DIR/.git" ]; then
    printf 'coding harness: %s (origin unavailable without Git)\n' "$HARNESS_DIR"
  else
    warn "coding harness checkout is not available at $HARNESS_DIR"
  fi

  verify_harness_link "$HARNESS_DIR/skills" "$HOME/.agents/skills"
  verify_harness_link "$HARNESS_DIR/skills" "$HOME/.claude/skills"
  verify_harness_link "$HARNESS_DIR/.pi/agent/themes" "$HOME/.pi/agent/themes"
  verify_harness_link "$HARNESS_DIR/.pi/agent/prompts" "$HOME/.pi/agent/prompts"
  verify_harness_link "$HARNESS_DIR/.pi/agent/extensions" "$HOME/.pi/agent/extensions"
  verify_harness_link "$HARNESS_DIR/AGENTS.md" "$HOME/.pi/agent/AGENTS.md"
  verify_harness_link "$HARNESS_DIR/AGENTS.md" "$HOME/.agents/AGENTS.md"
  verify_harness_link "$HARNESS_DIR/CLAUDE.md" "$HOME/.claude/CLAUDE.md"
}

main() {
  case ${1:-} in
    -h|--help) usage; exit 0 ;;
    '') ;;
    *) fail "unknown option: $1" ;;
  esac

  bootstrap_init
  refresh_standard_paths
  set_java_environment
  info 'Installed versions'

  if command -v mise >/dev/null 2>&1; then
    print_command_version mise
  elif [ "$PLATFORM" != macos ]; then
    warn 'mise is not available'
  fi

  for command_name in git git-lfs gh glab node npm bun tsc typescript-language-server tsx tmux nvim btop htop lazygit tig mc yazi mdc jq tree wget fzf fd zoxide rg revdiff java javac mvn; do
    print_command_version "$command_name"
  done
  print_yazi_support
  print_font_support

  if [ "$PLATFORM" != ubuntu ]; then
    print_command_version gradle
  fi

  print_harness_status

  if [ "$PLATFORM" = omarchy ]; then
    printf 'Claude Code, Codex, OpenCode, and Pi install through Omarchy when first launched.\n'
  else
    for agent in claude codex opencode pi; do
      if command -v "$agent" >/dev/null 2>&1; then
        printf '%s: installed\n' "$agent"
      else
        warn "$agent is not available in the current PATH"
      fi
    done
  fi
}

main "$@"

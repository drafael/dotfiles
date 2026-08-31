#!/bin/sh

set -eu

DOTFILES_DIR=$(CDPATH= cd -- "$(dirname -- "$0")/.." && pwd)
SOURCE_CONFIG_DIR="$DOTFILES_DIR/.config"
XDG_CONFIG_HOME=${XDG_CONFIG_HOME:-"$HOME/.config"}
BACKUP_BASE="$HOME/.dotfiles-backups"
BACKUP_DIR=""

fail() {
  printf 'error: %s\n' "$*" >&2
  exit 1
}

create_backup_dir() {
  if [ -n "$BACKUP_DIR" ]; then
    return
  fi

  timestamp=$(date '+%Y%m%d-%H%M%S')
  BACKUP_DIR="$BACKUP_BASE/$timestamp"
  suffix=0
  while [ -e "$BACKUP_DIR" ]; do
    suffix=$((suffix + 1))
    BACKUP_DIR="$BACKUP_BASE/$timestamp-$suffix"
  done
  mkdir -p "$BACKUP_DIR"
}

backup_path() {
  backup_source=$1
  backup_relative=${backup_source#"$HOME"/}
  create_backup_dir
  backup_destination="$BACKUP_DIR/$backup_relative"
  mkdir -p "$(dirname -- "$backup_destination")"
  mv "$backup_source" "$backup_destination"
  printf 'backed up %s -> %s\n' "$backup_source" "$backup_destination"
}

link_path() {
  link_source=$1
  link_destination=$2

  if [ -L "$link_destination" ] && [ "$(readlink "$link_destination")" = "$link_source" ]; then
    printf 'linked     %s\n' "$link_destination"
    return
  fi

  if [ -e "$link_destination" ] || [ -L "$link_destination" ]; then
    backup_path "$link_destination"
  fi

  ln -s "$link_source" "$link_destination"
  printf 'linked     %s -> %s\n' "$link_destination" "$link_source"
}

main() {
  [ "$(id -u)" -ne 0 ] || fail 'run this script as your normal user, not root'
  [ -d "$SOURCE_CONFIG_DIR" ] || fail "configuration directory not found: $SOURCE_CONFIG_DIR"

  mkdir -p "$XDG_CONFIG_HOME"

  for source in "$SOURCE_CONFIG_DIR"/* "$SOURCE_CONFIG_DIR"/.[!.]* "$SOURCE_CONFIG_DIR"/..?*; do
    if [ ! -e "$source" ] && [ ! -L "$source" ]; then
      continue
    fi

    name=${source##*/}
    link_path "$source" "$XDG_CONFIG_HOME/$name"
  done

  if [ -n "$BACKUP_DIR" ]; then
    printf 'Existing configuration was saved under %s\n' "$BACKUP_DIR"
  fi
}

main "$@"

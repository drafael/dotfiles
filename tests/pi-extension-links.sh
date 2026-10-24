#!/bin/sh
set -eu

repository=$(CDPATH= cd -- "$(dirname -- "$0")/.." && pwd)
work=$(mktemp -d "${TMPDIR:-/tmp}/pi-extension-links-test.XXXXXX")
trap 'rm -rf "$work"' EXIT HUP INT TERM
mkdir -p "$work/bin"
cp "$repository/bootstrap/lib.sh" "$repository/bootstrap/packages.sh" "$work/"
sed '$d' "$repository/bootstrap/coding-agents.sh" >"$work/bootstrap.sh"
cat >>"$work/bootstrap.sh" <<'EOF'
bootstrap_init() { PLATFORM=${TEST_PLATFORM:-macos}; }
install_agents() { :; }
install_revdiff() { :; }
install_revdiff_integrations() { :; }
install_herdr_codex_integration() { :; }
main
EOF
sed '$d' "$repository/bootstrap/verify.sh" >"$work/verify.sh"
printf '\nprint_harness_status\n' >>"$work/verify.sh"
for utility in awk basename cat chmod cmp cp date dirname find git grep ln mkdir mktemp mv readlink rm sed sh sort tr wc; do
  ln -s "$(command -v "$utility")" "$work/bin/$utility"
done
cat >"$work/bin/herdr" <<'EOF'
#!/bin/sh
set -eu
printf '%s\n' "$*" >>"$HERDR_CALLS"
[ "$*" = 'integration install pi' ]
agent_dir=${PI_CODING_AGENT_DIR:-$HOME/.pi/agent}
[ -d "$agent_dir/extensions" ]
[ ! -L "$agent_dir/extensions" ]
[ "${HERDR_FAIL:-0}" = 0 ] || exit 42
[ "${HERDR_NO_FILE:-0}" = 0 ] || exit 0
printf '// generated integration\n' >"$agent_dir/extensions/herdr-agent-state.ts"
EOF
chmod +x "$work/bin/herdr"
PATH="$work/bin"
HERDR_CALLS="$work/herdr-calls"
export PATH HERDR_CALLS

fixture() {
  HOME="$work/$1"
  export HOME
  unset PI_CODING_AGENT_DIR HERDR_FAIL HERDR_NO_FILE
  harness="$HOME/code/harness"
  source_dir="$harness/.pi/agent/extensions"
  destination="$HOME/.pi/agent/extensions"
  mkdir -p "$harness/skills" "$harness/.pi/agent/themes" "$harness/.pi/agent/prompts" "$source_dir"
  : >"$harness/AGENTS.md"
  : >"$harness/CLAUDE.md"
  printf '{}\n' >"$harness/.pi/agent/stt.json"
  printf 'export default function () {}\n' >"$source_dir/auto-java-coder.ts"
  printf 'export default function () {}\n' >"$source_dir/auto-typescript-coder.ts"
  git init -q "$harness"
  git -C "$harness" remote add origin https://github.com/drafael/coding-harness.git
  git -C "$harness" add .
  git -C "$harness" status --porcelain=v1 >"$work/source-before"
  : >"$HERDR_CALLS"
}

run_bootstrap() {
  sh "$work/bootstrap.sh" >"$work/output" 2>"$work/error"
  git -C "$harness" status --porcelain=v1 >"$work/source-after"
  cmp "$work/source-before" "$work/source-after"
}

reject() {
  status=0
  sh "$work/bootstrap.sh" >"$work/output" 2>"$work/error" || status=$?
  if [ "$status" = 0 ]; then
    printf 'expected rejection: %s\n' "$1" >&2
    exit 1
  fi
  grep -Fq "$1" "$work/error"
}

fixture fresh
[ ! -e "$HOME/.pi/agent" ]
run_bootstrap
[ -d "$destination" ]
[ ! -L "$destination" ]
for name in auto-java-coder.ts auto-typescript-coder.ts; do
  [ "$(readlink "$destination/$name")" = "$source_dir/$name" ]
done
[ -f "$destination/herdr-agent-state.ts" ]
[ ! -L "$destination/herdr-agent-state.ts" ]
grep -Fxq 'integration install pi' "$HERDR_CALLS"
rm "$destination/auto-java-coder.ts"
ln -s ../../../code/harness/.pi/agent/extensions/auto-java-coder.ts "$destination/auto-java-coder.ts"
printf '// keep local integration edits\n' >"$destination/herdr-agent-state.ts"
printf '// keep local extension\n' >"$destination/local.ts"
: >"$HERDR_CALLS"
run_bootstrap
[ ! -s "$HERDR_CALLS" ]
[ "$(readlink "$destination/auto-java-coder.ts")" = ../../../code/harness/.pi/agent/extensions/auto-java-coder.ts ]
grep -Fq 'keep local integration edits' "$destination/herdr-agent-state.ts"
grep -Fq 'keep local extension' "$destination/local.ts"
[ ! -d "$HOME/.dotfiles-backups" ]
sh "$work/verify.sh" >"$work/verify.out" 2>"$work/verify.err"
[ ! -s "$work/verify.err" ]
grep -Fq "$destination/auto-java-coder.ts" "$work/verify.out"

fixture copies
mkdir -p "$destination"
cp "$source_dir/auto-java-coder.ts" "$source_dir/auto-typescript-coder.ts" "$destination/"
run_bootstrap
for name in auto-java-coder.ts auto-typescript-coder.ts; do
  backup=$(find "$HOME/.dotfiles-backups" -type f -name "$name" -print)
  cmp "$backup" "$source_dir/$name"
  [ -L "$destination/$name" ]
done

fixture modified-copy
mkdir -p "$destination"
cp "$source_dir/auto-java-coder.ts" "$destination/"
printf '// local edits\n' >"$destination/auto-typescript-coder.ts"
reject 'conflicting Pi extension'
[ ! -L "$destination/auto-java-coder.ts" ]
grep -Fq 'local edits' "$destination/auto-typescript-coder.ts"
[ ! -d "$HOME/.dotfiles-backups" ]
[ ! -s "$HERDR_CALLS" ]

for target_style in absolute relative; do
  fixture "directory-link-$target_style"
  mkdir -p "$(dirname "$destination")"
  if [ "$target_style" = absolute ]; then
    ln -s "$source_dir" "$destination"
  else
    ln -s ../../code/harness/.pi/agent/extensions "$destination"
  fi
  original_target=$(readlink "$destination")
  run_bootstrap
  [ -d "$destination" ]
  [ ! -L "$destination" ]
  for name in auto-java-coder.ts auto-typescript-coder.ts; do
    [ "$(readlink "$destination/$name")" = "$source_dir/$name" ]
  done
  backup=$(find "$HOME/.dotfiles-backups" -type l -name extensions -print)
  [ -L "$backup" ]
  [ "$(readlink "$backup")" = "$original_target" ]
  [ -f "$destination/herdr-agent-state.ts" ]
  [ ! -L "$destination/herdr-agent-state.ts" ]
  [ ! -e "$source_dir/herdr-agent-state.ts" ]
done

fixture unexpected-source-entry
mkdir -p "$(dirname "$destination")"
ln -s "$source_dir" "$destination"
printf '// existing generated or local code\n' >"$source_dir/herdr-agent-state.ts"
reject 'unexpected entry in symlinked harness extensions'
[ -L "$destination" ]
grep -Fq 'existing generated or local code' "$source_dir/herdr-agent-state.ts"
[ ! -s "$HERDR_CALLS" ]

fixture foreign-link
mkdir -p "$HOME/foreign" "$(dirname "$destination")"
ln -s "$HOME/foreign" "$destination"
reject 'unexpected Pi extensions directory symlink'
[ "$(readlink "$destination")" = "$HOME/foreign" ]
[ ! -s "$HERDR_CALLS" ]

fixture foreign-file-link
mkdir -p "$destination"
printf '// foreign code\n' >"$HOME/foreign.ts"
ln -s "$HOME/foreign.ts" "$destination/auto-java-coder.ts"
reject 'conflicting Pi extension'
[ "$(readlink "$destination/auto-java-coder.ts")" = "$HOME/foreign.ts" ]

fixture reserved-name
printf '// reserved collision\n' >"$source_dir/herdr-agent-state.ts"
git -C "$harness" add .
reject 'reserved for Herdr'
[ ! -e "$destination" ]

fixture untracked-source
printf '// untracked experiment\n' >"$source_dir/experiment.ts"
git -C "$harness" status --porcelain=v1 >"$work/source-before"
run_bootstrap
[ ! -e "$destination/experiment.ts" ]
[ -f "$source_dir/experiment.ts" ]

fixture custom-root
PI_CODING_AGENT_DIR="$HOME/custom Pi agent"
export PI_CODING_AGENT_DIR
[ ! -e "$PI_CODING_AGENT_DIR" ]
run_bootstrap
[ -d "$PI_CODING_AGENT_DIR/extensions" ]
[ ! -L "$PI_CODING_AGENT_DIR/extensions" ]
[ -L "$PI_CODING_AGENT_DIR/extensions/auto-java-coder.ts" ]
[ -f "$PI_CODING_AGENT_DIR/extensions/herdr-agent-state.ts" ]
[ ! -e "$destination" ]

fixture checkout-root
PI_CODING_AGENT_DIR="$harness/.pi/agent"
export PI_CODING_AGENT_DIR
reject 'Pi agent directory must be outside the harness checkout'
[ ! -s "$HERDR_CALLS" ]

fixture checkout-new-root
PI_CODING_AGENT_DIR="$harness/new-agent/config"
export PI_CODING_AGENT_DIR
reject 'Pi agent directory must be outside the harness checkout'
[ ! -e "$harness/new-agent" ]

fixture stale-link
run_bootstrap
git -C "$harness" mv .pi/agent/extensions/auto-java-coder.ts '.pi/agent/extensions/renamed coder.js'
git -C "$harness" status --porcelain=v1 >"$work/source-before"
run_bootstrap
[ -L "$destination/renamed coder.js" ]
[ -L "$destination/auto-java-coder.ts" ]
[ ! -e "$destination/auto-java-coder.ts" ]
grep -Fq 'broken Pi extension link' "$work/error"

fixture native-link-collision
mkdir -p "$destination"
printf '// foreign integration\n' >"$HOME/foreign.ts"
ln -s "$HOME/foreign.ts" "$destination/herdr-agent-state.ts"
reject 'conflicting Herdr Pi integration'
[ ! -e "$destination/auto-java-coder.ts" ]
[ ! -s "$HERDR_CALLS" ]

fixture native-failure
status=0
HERDR_FAIL=1 sh "$work/bootstrap.sh" >"$work/output" 2>"$work/error" || status=$?
[ "$status" = 42 ]
[ ! -e "$destination/herdr-agent-state.ts" ]
run_bootstrap
[ -f "$destination/herdr-agent-state.ts" ]

fixture missing-artifact
HERDR_NO_FILE=1 reject 'Herdr Pi integration file was not created'
printf 'Pi per-extension links, migrations, conflicts, overrides, native integration, and rerun checks passed.\n'

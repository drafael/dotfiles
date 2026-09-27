#!/bin/sh
set -eu

test_repository=$(CDPATH= cd -- "$(dirname -- "$0")/.." && pwd)
test_work=$(mktemp -d "${TMPDIR:-/tmp}/fedora-yazi-test.XXXXXX")
trap 'rm -rf "$test_work"' EXIT HUP INT TERM
mkdir -p "$test_work/bin"
ln -s "$(command -v jq)" "$test_work/bin/jq"
test_path="$test_work/bin:/usr/bin:/bin:/sbin:/usr/sbin"
sed '$d' "$test_repository/bootstrap/cli-tools.sh" >"$test_work/cli-tools.sh"
cp "$test_repository/bootstrap/lib.sh" "$test_work/lib.sh"

python3 - "$test_work/archive.zip" <<'PY'
import sys
import zipfile

with zipfile.ZipFile(sys.argv[1], "w") as archive:
    archive.writestr("yazi-x86_64-unknown-linux-gnu/yazi", "mock yazi\n")
    archive.writestr("yazi-x86_64-unknown-linux-gnu/ya", "mock ya\n")
PY
checksum=$(sha256sum "$test_work/archive.zip" | awk '{ print $1 }')

printf '%s\n' '
uname() { printf "x86_64\n"; }
curl() {
  for argument do
    if [ "$argument" = -o ]; then
      shift
      destination=$1
      break
    fi
    shift
  done
  case $destination in
    *.json) cp "$TEST_METADATA" "$destination" ;;
    *.zip) cp "$TEST_ARCHIVE" "$destination" ;;
    *) return 1 ;;
  esac
}
install_fedora_yazi' >>"$test_work/cli-tools.sh"

for scenario in valid tampered; do
  mkdir -p "$test_work/$scenario-home"
  digest=$checksum
  if [ "$scenario" = tampered ]; then
    digest=0000000000000000000000000000000000000000000000000000000000000000
  fi
  printf '{"assets":[{"name":"yazi-x86_64-unknown-linux-gnu.zip","browser_download_url":"https://example.invalid/yazi.zip","digest":"sha256:%s"}]}\n' \
    "$digest" >"$test_work/$scenario.json"
  if [ "$scenario" = valid ]; then
    PATH="$test_path" HOME="$test_work/$scenario-home" TEST_METADATA="$test_work/$scenario.json" TEST_ARCHIVE="$test_work/archive.zip" \
      sh "$test_work/cli-tools.sh"
    [ -x "$test_work/$scenario-home/.local/bin/yazi" ]
    [ -x "$test_work/$scenario-home/.local/bin/ya" ]
  else
    if PATH="$test_path" HOME="$test_work/$scenario-home" TEST_METADATA="$test_work/$scenario.json" TEST_ARCHIVE="$test_work/archive.zip" \
      sh "$test_work/cli-tools.sh" >"$test_work/tampered.out" 2>"$test_work/tampered.err"; then
      printf 'tampered Yazi archive unexpectedly passed\n' >&2
      exit 1
    fi
    [ ! -e "$test_work/$scenario-home/.local/bin/yazi" ]
    grep -Fq 'FAILED' "$test_work/tampered.out" "$test_work/tampered.err"
  fi
done
printf 'Fedora Yazi verified install and tamper rejection passed.\n'

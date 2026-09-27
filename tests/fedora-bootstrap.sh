#!/bin/sh
set -eu

test_repository=$(CDPATH= cd -- "$(dirname -- "$0")/.." && pwd)
work=$(mktemp -d "${TMPDIR:-/tmp}/fedora-bootstrap-test.XXXXXX")
trap 'rm -rf "$work"' EXIT HUP INT TERM
cp "$test_repository/bootstrap/lib.sh" "$work/lib.sh"
sed '$d' "$test_repository/bootstrap/1password.sh" >"$work/1password.sh"
cp "$work/1password.sh" "$work/1password-arm.sh"
cp "$work/1password.sh" "$work/1password-key.sh"
sed '$d' "$test_repository/bootstrap/containers.sh" >"$work/containers.sh"

(
  BOOTSTRAP_DIR="$test_repository/bootstrap"
  . "$BOOTSTRAP_DIR/lib.sh"
  rpm() { [ "$2" = git ]; }
  sudo() { printf '%s\n' "$*" >>"$work/dnf-calls"; }
  ensure_fedora_packages git curl
)
grep -Fxq 'dnf install -y curl' "$work/dnf-calls"
: >"$work/dnf-calls"
(
  BOOTSTRAP_DIR="$test_repository/bootstrap"
  . "$BOOTSTRAP_DIR/lib.sh"
  rpm() { return 0; }
  sudo() { printf '%s\n' "$*" >>"$work/dnf-calls"; }
  ensure_fedora_packages git curl
)
[ ! -s "$work/dnf-calls" ]

printf '%s\n' '
need_cli() { return 0; }
need_desktop() { [ "$MODE" = full ]; }
rpm() { return 1; }
install_fedora_repository() { repo_arch=x86_64; }
sudo() {
  printf "%s\n" "$*" >>"$CALLS"
  if [ "$1" = dnf ] && [ "${4:-}" = repoquery ] && [ "$MODE" != no-vendor ]; then
    for last_argument do :; done
    printf "%s\n" "$last_argument"
  fi
}
install_fedora' >>"$work/1password.sh"

printf '%s\n' '
need_desktop() { return 0; }
uname() { printf "aarch64\n"; }
install_fedora_repository' >>"$work/1password-arm.sh"
printf '%s\n' '
gpg() {
  printf "pub:::::::::\\nfpr:::::::::%s:\\n" "$KEY_FINGERPRINT"
}
verify_vendor_key /tmp/onepassword-test-key' >>"$work/1password-key.sh"

MODE=cli CALLS="$work/cli-calls" sh "$work/1password.sh"
grep -Fxq 'dnf install -y --from-repo=1password 1password-cli' "$work/cli-calls"
MODE=full CALLS="$work/full-calls" sh "$work/1password.sh"
grep -Fxq 'dnf install -y --from-repo=1password 1password 1password-cli' "$work/full-calls"
if MODE=no-vendor CALLS="$work/missing-calls" sh "$work/1password.sh" >"$work/missing.out" 2>"$work/missing.err"; then
  printf 'missing vendor RPM unexpectedly passed\n' >&2
  exit 1
fi
grep -Fq 'repository does not provide 1password-cli' "$work/missing.err"
if grep -Fq 'dnf install -y --from-repo' "$work/missing-calls"; then
  printf 'missing vendor RPM reached installation\n' >&2
  exit 1
fi
if sh "$work/1password-arm.sh" >"$work/arm.out" 2>"$work/arm.err"; then
  printf 'ARM64 desktop unexpectedly passed\n' >&2
  exit 1
fi
grep -Fq 'desktop is not in the Fedora ARM64 RPM repository' "$work/arm.err"
[ ! -e "$work/arm-calls" ]
KEY_FINGERPRINT=3FEF9748469ADBE15DA7CA80AC2D62742012EA22 sh "$work/1password-key.sh"
if KEY_FINGERPRINT=0000000000000000000000000000000000000000 sh "$work/1password-key.sh" >"$work/key.out" 2>"$work/key.err"; then
  printf 'mismatched signing key unexpectedly passed\n' >&2
  exit 1
fi
grep -Fq 'signing key fingerprint mismatch' "$work/key.err"

printf '%s\n' '
PLATFORM=fedora
CONTAINER_RUNTIME=docker
docker() { return 0; }
install_linux_kubernetes_tools() { printf "kubernetes checked\n"; }
install_fedora_tools' >>"$work/containers.sh"
sh "$work/containers.sh" >"$work/containers.out"
grep -Fxq 'kubernetes checked' "$work/containers.out"
printf 'Fedora missing-package, vendor-source, ARM64 routing, key-fingerprint, and container checks passed.\n'

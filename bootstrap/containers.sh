#!/bin/sh

set -eu

BOOTSTRAP_DIR=$(CDPATH= cd -- "$(dirname -- "$0")" && pwd)
# shellcheck source=lib.sh
. "$BOOTSTRAP_DIR/lib.sh"

CONTAINER_RUNTIME=docker

usage() {
  printf '%s\n' \
    'Usage: containers.sh [--runtime=docker|podman]' \
    '' \
    'Install a container runtime and local Kubernetes command-line tools.' \
    'The default runtime is Docker. The script does not explicitly start or' \
    'enable services, create clusters, or grant additional system permissions.'
}

parse_arguments() {
  while [ "$#" -gt 0 ]; do
    case $1 in
      --runtime=*)
        CONTAINER_RUNTIME=${1#*=}
        [ -n "$CONTAINER_RUNTIME" ] || fail 'missing value for --runtime'
        ;;
      --runtime)
        [ "$#" -ge 2 ] || fail 'missing value for --runtime'
        shift
        CONTAINER_RUNTIME=$1
        ;;
      -h|--help)
        usage
        exit 0
        ;;
      *) fail "unknown option: $1" ;;
    esac
    shift
  done

  case $CONTAINER_RUNTIME in
    docker|podman) ;;
    *) fail "unsupported container runtime: $CONTAINER_RUNTIME" ;;
  esac
}

linux_release_architecture() {
  case $(uname -m) in
    x86_64|amd64) printf '%s\n' amd64 ;;
    aarch64|arm64) printf '%s\n' arm64 ;;
    *) fail "unsupported Linux architecture: $(uname -m)" ;;
  esac
}

valid_release_version() {
  case $1 in
    v[0-9]*)
      version_number=${1#v}
      case $version_number in
        *[!0123456789.]*|.*|*.|*..*) return 1 ;;
        *) return 0 ;;
      esac
      ;;
    *) return 1 ;;
  esac
}

verified_download() {
  label=$1
  download_url=$2
  checksum_url=$3
  destination=$4

  verified_temp_dir=$(mktemp -d "${TMPDIR:-/tmp}/dotfiles-container-download.XXXXXX")
  verified_download_path="$verified_temp_dir/download"
  verified_checksum_file="$verified_temp_dir/download.sha256"
  if ! curl -fsSL "$download_url" -o "$verified_download_path"; then
    rm -rf "$verified_temp_dir"
    fail "failed to download $label"
  fi
  if ! curl -fsSL "$checksum_url" -o "$verified_checksum_file"; then
    rm -rf "$verified_temp_dir"
    fail "failed to download the $label checksum"
  fi
  expected_checksum=$(awk 'NR == 1 { print $1 }' "$verified_checksum_file")
  case $expected_checksum in
    ''|*[!0123456789abcdefABCDEF]*)
      rm -rf "$verified_temp_dir"
      fail "$label did not publish a valid SHA-256 checksum"
      ;;
  esac
  if [ "${#expected_checksum}" -ne 64 ]; then
    rm -rf "$verified_temp_dir"
    fail "$label did not publish a valid SHA-256 checksum"
  fi
  printf '%s  %s\n' "$expected_checksum" download >"$verified_temp_dir/checksum"
  if ! (cd "$verified_temp_dir" && sha256sum -c checksum); then
    rm -rf "$verified_temp_dir"
    fail "$label checksum verification failed"
  fi
  mv "$verified_download_path" "$destination"
  rm -rf "$verified_temp_dir"
}

install_verified_binary() {
  label=$1
  command_name=$2
  download_url=$3
  checksum_url=$4

  command -v "$command_name" >/dev/null 2>&1 && return
  ensure_real_directory "$HOME/.local/bin"
  staged_binary=$(mktemp "${TMPDIR:-/tmp}/dotfiles-container-binary.XXXXXX")
  rm -f "$staged_binary"
  info "Installing $label"
  verified_download "$label" "$download_url" "$checksum_url" "$staged_binary"
  install -m 0755 "$staged_binary" "$HOME/.local/bin/$command_name"
  rm -f "$staged_binary"
  refresh_standard_paths
  require_command "$command_name"
}

install_ubuntu_kubectl() {
  command -v kubectl >/dev/null 2>&1 && return
  architecture=$(linux_release_architecture)
  kubectl_version=$(curl -fsSL https://dl.k8s.io/release/stable.txt)
  valid_release_version "$kubectl_version" || fail 'could not determine the current stable kubectl release'
  kubectl_url="https://dl.k8s.io/release/$kubectl_version/bin/linux/$architecture/kubectl"
  install_verified_binary kubectl kubectl "$kubectl_url" "$kubectl_url.sha256"
}

install_ubuntu_minikube() {
  command -v minikube >/dev/null 2>&1 && return
  architecture=$(linux_release_architecture)
  metadata=$(mktemp "${TMPDIR:-/tmp}/dotfiles-minikube-release.XXXXXX")
  curl -fsSL https://api.github.com/repos/kubernetes/minikube/releases/latest -o "$metadata"
  minikube_version=$(jq -er '.tag_name' "$metadata") || {
    rm -f "$metadata"
    fail 'could not determine the latest Minikube release'
  }
  rm -f "$metadata"
  valid_release_version "$minikube_version" || fail 'Minikube returned an invalid release version'
  minikube_url="https://github.com/kubernetes/minikube/releases/download/$minikube_version/minikube-linux-$architecture"
  install_verified_binary Minikube minikube "$minikube_url" "$minikube_url.sha256"
}

install_ubuntu_helm() {
  command -v helm >/dev/null 2>&1 && return
  architecture=$(linux_release_architecture)
  temp_dir=$(mktemp -d "${TMPDIR:-/tmp}/dotfiles-helm.XXXXXX")
  metadata="$temp_dir/release.json"
  curl -fsSL https://api.github.com/repos/helm/helm/releases/latest -o "$metadata"
  helm_version=$(jq -er '.tag_name' "$metadata") || {
    rm -rf "$temp_dir"
    fail 'could not determine the latest Helm release'
  }
  if ! valid_release_version "$helm_version"; then
    rm -rf "$temp_dir"
    fail 'Helm returned an invalid release version'
  fi

  archive_name="helm-$helm_version-linux-$architecture.tar.gz"
  archive="$temp_dir/$archive_name"
  helm_url="https://get.helm.sh/$archive_name"
  info "Installing Helm $helm_version"
  verified_download Helm "$helm_url" "$helm_url.sha256" "$archive"
  mkdir -p "$temp_dir/extracted"
  tar -xzf "$archive" -C "$temp_dir/extracted"
  helm_binary="$temp_dir/extracted/linux-$architecture/helm"
  [ -f "$helm_binary" ] || {
    rm -rf "$temp_dir"
    fail "$archive_name did not contain the Helm binary"
  }
  ensure_real_directory "$HOME/.local/bin"
  install -m 0755 "$helm_binary" "$HOME/.local/bin/helm"
  rm -rf "$temp_dir"
  refresh_standard_paths
  require_command helm
}

install_ubuntu_kubernetes_tools() {
  ensure_ubuntu_packages ca-certificates curl jq
  install_ubuntu_kubectl
  install_ubuntu_helm
  install_ubuntu_minikube
}

ubuntu_has_vendor_docker_packages() {
  for package_name in docker-ce docker-ce-cli docker-compose-plugin docker-buildx-plugin containerd.io; do
    if dpkg-query -W -f='${Status}' "$package_name" 2>/dev/null | grep -q 'install ok installed'; then
      return 0
    fi
  done
  return 1
}

install_ubuntu_runtime() {
  ensure_ubuntu_packages software-properties-common
  sudo add-apt-repository -y universe

  case $CONTAINER_RUNTIME in
    docker)
      if command -v docker >/dev/null 2>&1 &&
        docker compose version >/dev/null 2>&1 &&
        docker buildx version >/dev/null 2>&1; then
        return
      fi
      if ubuntu_has_vendor_docker_packages; then
        fail 'an incomplete vendor Docker installation exists; repair it with Docker packages before rerunning this script'
      fi
      ensure_ubuntu_packages docker.io docker-compose-v2 docker-buildx
      ;;
    podman)
      ensure_ubuntu_packages podman podman-compose
      ;;
  esac
}

ensure_macos_docker_plugin() {
  subcommand=$1
  plugin_name=$2
  formula_name=$3

  docker "$subcommand" version >/dev/null 2>&1 && return
  plugin_source="$(brew --prefix)/lib/docker/cli-plugins/$plugin_name"
  [ -e "$plugin_source" ] || fail "Homebrew did not install the $plugin_name Docker plugin"
  plugin_destination="$HOME/.docker/cli-plugins/$plugin_name"
  if [ -e "$plugin_destination" ] || [ -L "$plugin_destination" ]; then
    if symlink_points_to_path "$plugin_destination" "$plugin_source"; then
      return
    fi
    fail "$plugin_destination already exists but Docker cannot use it; preserve or remove it manually"
  fi
  mkdir -p "$(dirname -- "$plugin_destination")"
  ln -s "$plugin_source" "$plugin_destination"
  docker "$subcommand" version >/dev/null 2>&1 || fail "Docker cannot discover the $formula_name plugin"
}

install_macos_tools() {
  case $CONTAINER_RUNTIME in
    docker)
      ensure_brew_formulas colima docker docker-compose docker-buildx kubernetes-cli helm minikube
      ensure_macos_docker_plugin compose docker-compose docker-compose
      ensure_macos_docker_plugin buildx docker-buildx docker-buildx
      ;;
    podman)
      ensure_brew_formulas podman podman-compose kubernetes-cli helm minikube
      ;;
  esac
}

install_arch_tools() {
  case $CONTAINER_RUNTIME in
    docker)
      ensure_arch_packages docker docker-compose docker-buildx kubectl helm minikube
      ;;
    podman)
      ensure_arch_packages podman podman-compose kubectl helm minikube
      ;;
  esac
}

install_omarchy_tools() {
  case $CONTAINER_RUNTIME in
    docker)
      ensure_omarchy_packages docker docker-compose docker-buildx kubectl helm minikube
      ;;
    podman)
      ensure_omarchy_packages podman podman-compose kubectl helm minikube
      ;;
  esac
}

verify_container_tools() {
  info 'Verifying container and Kubernetes command-line tools'
  case $CONTAINER_RUNTIME in
    docker)
      require_command docker
      docker --version
      docker compose version
      docker buildx version
      if [ "$PLATFORM" = macos ]; then
        require_command colima
        colima version
      fi
      ;;
    podman)
      require_command podman
      podman --version
      require_command podman-compose
      podman-compose --version
      ;;
  esac

  require_command kubectl
  kubectl version --client
  require_command helm
  helm version
  require_command minikube
  minikube version
}

print_next_steps() {
  info 'Container runtime next steps'
  case "$PLATFORM:$CONTAINER_RUNTIME" in
    macos:docker)
      printf '%s\n' \
        'Start the runtime when needed: colima start' \
        'Then verify it: docker run --rm hello-world' \
        'Create a local cluster when needed: minikube start --driver=docker'
      ;;
    macos:podman)
      printf '%s\n' \
        'Create and start the runtime when needed: podman machine init && podman machine start' \
        'Then verify it: podman run --rm docker.io/library/hello-world'
      ;;
    ubuntu:docker|arch:docker)
      printf '%s\n' \
        'Start Docker when needed: sudo systemctl enable --now docker' \
        'Docker group membership grants root-equivalent access and is not changed by this script.' \
        'After arranging unprivileged Docker access, create a cluster with: minikube start --driver=docker'
      ;;
    omarchy:docker)
      printf '%s\n' \
        'Omarchy keeps its native Docker socket activation and sudo policy.' \
        'Use sudo docker, or review Setup > Security > Sudoless Docker before changing access.' \
        'Minikube Docker-driver use requires unprivileged access to the Docker daemon.'
      ;;
    ubuntu:podman|arch:podman|omarchy:podman)
      printf '%s\n' \
        'Verify the rootless runtime when needed: podman info' \
        'Minikube supports Podman as an experimental driver: minikube start --driver=podman'
      ;;
  esac
  printf '%s\n' 'No runtime, service, or cluster was explicitly started; package-manager service defaults may apply.'
}

install_container_tools() {
  info "Ensuring $CONTAINER_RUNTIME container and Kubernetes tools are installed on $PLATFORM"
  case $PLATFORM in
    macos)
      install_macos_tools
      ;;
    ubuntu)
      install_ubuntu_runtime
      install_ubuntu_kubernetes_tools
      ;;
    arch)
      install_arch_tools
      ;;
    omarchy)
      install_omarchy_tools
      ;;
  esac
}

main() {
  parse_arguments "$@"
  bootstrap_init
  install_container_tools
  verify_container_tools
  print_next_steps
}

main "$@"

# Invoked by the Nix-packaged dev-setup command, as the normal user.
# Pass a full SDKMAN Java 21 identifier to also install/select that JDK.
set -e -o pipefail

if [[ "$EUID" -eq 0 ]]; then
  echo "Run dev-setup as your normal user, without sudo." >&2
  exit 1
fi
if [[ $# -gt 1 || ( $# -eq 1 && ! "$1" =~ ^21\.[0-9]+\.[0-9]+.*-[a-zA-Z0-9]+$ ) ]]; then
  echo "Usage: dev-setup [Java-21-identifier-from-sdk-list-java]" >&2
  exit 2
fi

export VP_HOME="${VP_HOME:-$HOME/.vite-plus}"
export SDKMAN_DIR="${SDKMAN_DIR:-$HOME/.sdkman}"
export PATH="$VP_HOME/bin:$HOME/.local/bin:$PATH"

setup_tmp="$(mktemp -d)"
trap 'rm -f "$setup_tmp/vite-install.sh" "$setup_tmp/sdkman-install.sh"; rmdir "$setup_tmp"' EXIT

if [[ ! -x "$VP_HOME/bin/vp" ]]; then
  curl --fail --show-error --location https://vite.plus -o "$setup_tmp/vite-install.sh"
  # Home Manager provides shell initialization; CI tolerates read-only rc files.
  CI=true VP_NODE_MANAGER=yes bash "$setup_tmp/vite-install.sh"
fi
vp env setup
vp env on
vp env default lts
vp env default pnpm@10
vp env install lts pnpm@10

if [[ ! -s "$SDKMAN_DIR/bin/sdkman-init.sh" ]]; then
  curl --fail --show-error --location 'https://get.sdkman.io?rcupdate=false' -o "$setup_tmp/sdkman-install.sh"
  bash "$setup_tmp/sdkman-install.sh"
fi

# SDKMAN is a sourced shell function and does not support nounset.
set +u
# shellcheck disable=SC1091
source "$SDKMAN_DIR/bin/sdkman-init.sh"
if [[ $# -eq 1 ]]; then
  if [[ ! -d "$SDKMAN_DIR/candidates/java/$1" ]]; then
    sdk install java "$1"
  fi
  sdk default java "$1"
else
  echo 'Java 21: open a new terminal, run "sdk list java", then "dev-setup <21.x.y-vendor>".'
fi

uv python install --default 3.13
echo 'Setup complete. Open a new terminal; use vp env doctor, sdk current java, and uv python list.'

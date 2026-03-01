#!/bin/bash
set -euo pipefail

PLUGIN_DIR="$(cd "$(dirname "$0")" && pwd)"
BIN_DIR="${PLUGIN_DIR}/bin"
BINARY="${BIN_DIR}/agent-atuin"

# --- Release download settings ---
# Update this URL when releases are published
RELEASE_URL="https://github.com/victoria-klein/agent-atuin/releases"
VERSION="v0.1.0"

detect_platform() {
  local os arch
  os="$(uname -s)"
  arch="$(uname -m)"

  case "$os" in
    Darwin) os="apple-darwin" ;;
    Linux)  os="unknown-linux-gnu" ;;
    *)      echo "Unsupported OS: $os"; return 1 ;;
  esac

  case "$arch" in
    x86_64)  arch="x86_64" ;;
    aarch64|arm64) arch="aarch64" ;;
    *)       echo "Unsupported architecture: $arch"; return 1 ;;
  esac

  echo "${arch}-${os}"
}

download_binary() {
  local platform="$1"
  local archive="atuin-${platform}.tar.gz"
  local url="${RELEASE_URL}/download/${VERSION}/${archive}"
  local tmpdir

  echo "Downloading agent-atuin ${VERSION} for ${platform}..."
  echo "  URL: ${url}"

  tmpdir="$(mktemp -d)"
  trap 'rm -rf "${tmpdir}"' RETURN

  if command -v curl &> /dev/null; then
    curl -fsSL -o "${tmpdir}/${archive}" "${url}"
  elif command -v wget &> /dev/null; then
    wget -q -O "${tmpdir}/${archive}" "${url}"
  else
    echo "Error: neither curl nor wget found"
    return 1
  fi

  tar xzf "${tmpdir}/${archive}" -C "${tmpdir}"
  mv "${tmpdir}/atuin" "${BINARY}"
  chmod +x "${BINARY}"
  echo "Downloaded agent-atuin to ${BINARY}"
}

# If binary already exists and is executable, skip download
if [ -x "${BINARY}" ]; then
  echo "agent-atuin binary already present at ${BINARY}"
else
  mkdir -p "${BIN_DIR}"

  # Try downloading a release binary
  platform="$(detect_platform)" || true
  if [ -n "${platform:-}" ]; then
    if download_binary "${platform}" 2>/dev/null; then
      echo "Successfully downloaded release binary."
    else
      echo "Download failed (releases may not be published yet)."
      echo ""
      # Fallback: check if agent-atuin is already in PATH
      if command -v agent-atuin &> /dev/null; then
        echo "Found agent-atuin in PATH, creating symlink..."
        ln -sf "$(command -v agent-atuin)" "${BINARY}"
      elif command -v atuin &> /dev/null; then
        echo "Found atuin in PATH, creating symlink as agent-atuin..."
        ln -sf "$(command -v atuin)" "${BINARY}"
      else
        echo "To get the binary, either:"
        echo "  1. Build from the agent-atuin repo:"
        echo "     git clone https://github.com/victoria-klein/agent-atuin.git"
        echo "     cd agent-atuin && cargo build --release -p atuin"
        echo "     cp target/release/atuin ${BINARY}"
        echo ""
        echo "  2. Or download a release from:"
        echo "     ${RELEASE_URL}"
        exit 1
      fi
    fi
  fi
fi

# Make scripts executable
chmod +x "${PLUGIN_DIR}/scripts/"*.sh 2>/dev/null || true

echo "Plugin ready at: ${PLUGIN_DIR}"

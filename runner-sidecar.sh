#!/bin/bash
set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROXY_NAME="amp-proxy"
NETWORK_NAME="amp-network"

# Project directory (configurable via environment or argument)
AMP_PROJECT="${AMP_PROJECT:-}"
LOG_DIR="${AMP_PROXY_LOG_DIR:-"$HOME"/.local/log/amp-proxy}"

# Parse command line arguments
while [[ $# -gt 0 ]]; do
  case $1 in
    --project)
      AMP_PROJECT="$2"
      shift 2
      ;; 
    --help)
      echo "Usage: $0 --project /path/to/project [-- amp args...]"
      echo ""
      echo "Options:"
      echo "  --project PATH    Project directory to mount at /worktree (required)"
      echo ""
      echo "Environment variables:"
      echo "  AMP_PROJECT       Project directory (alternative to --project)"
      echo ""
      echo "Amp config directories are automatically mounted from \$HOME:"
      echo "  \$HOME/.config/  \$HOME/.amp/  \$HOME/.local/  \$HOME/.cache/"
      exit 0
      ;; 
    --)
      shift
      break
      ;; 
    *)
      break
      ;; 
  esac
done

# Validate required arguments
if [[ -z "$AMP_PROJECT" ]]; then
  echo "ERROR: --project is required"
  echo "Usage: $0 --project /path/to/project"
  exit 1
fi

if [[ ! -d "$AMP_PROJECT" ]]; then
  echo "ERROR: Project directory does not exist: $AMP_PROJECT"
  exit 1
fi

# Container user UID (ampy is UID 1001 in the container)
CONTAINER_UID=1001

# Create log directory if it doesn't exist
mkdir -p "$LOG_DIR"

# Create network if it doesn't exist
podman network exists "$NETWORK_NAME" 2>/dev/null || podman network create "$NETWORK_NAME"

# Stop and remove existing proxy if running
podman rm -f "$PROXY_NAME" 2>/dev/null || true

# Start the proxy sidecar
echo "Starting proxy sidecar..."
echo "Logs will be written to: $LOG_DIR"
podman run -d \
  --name "$PROXY_NAME" \
  --replace \
  --cap-add=NET_ADMIN \
  -v "${SCRIPT_DIR}/blocklist.txt:/etc/squid/blocklist.txt:ro,z" \
  amp_proxy

# Wait for proxy to be ready
echo "Waiting for proxy to start..."
sleep 2

# Check if proxy is still running
if ! podman ps --filter "name=$PROXY_NAME" --format "{{.Names}}" | grep -q "$PROXY_NAME"; then
  echo "ERROR: Proxy container failed to start. Logs:"
  podman logs "$PROXY_NAME"
  exit 1
fi

echo "Proxy running (amp container will share its network namespace)"

# Container user home directory
AMP_HOME=/home/ampy

# Run amp container sharing proxy's network namespace (transparent proxy)
echo "Starting amp container..."
echo "  HOME:    $HOME -> $AMP_HOME (in container)"
echo "  PROJECT: $AMP_PROJECT -> /worktree"
podman run -it --rm \
  --network "container:$PROXY_NAME" \
  --env-file "${SCRIPT_DIR}/envfile" \
  -v "$HOME/.config/:$AMP_HOME/.config:z" \
  -v "$HOME/.amp/:$AMP_HOME/.amp/:z" \
  -v "$HOME/.local/:$AMP_HOME/.local/:z" \
  -v "$HOME/.cache/:$AMP_HOME/.cache:z" \
  -v "$AMP_PROJECT:/worktree/:z" \
  --userns=keep-id:uid=$CONTAINER_UID \
  amp_in_a_box "$@"

# Cleanup proxy on exit
echo "Stopping proxy..."
podman stop "$PROXY_NAME"
podman rm "$PROXY_NAME"
#!/bin/bash
set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROXY_NAME="amp-proxy"
NETWORK_NAME="amp-network"
LOG_DIR="${AMP_PROXY_LOG_DIR:-$HOME/.local/log/amp-proxy}"

# Create log directory if it doesn't exist
mkdir -p "$LOG_DIR"

# Create network if it doesn't exist
podman network exists "$NETWORK_NAME" 2>/dev/null || podman network create "$NETWORK_NAME"

# Stop existing proxy if running
podman stop "$PROXY_NAME" 2>/dev/null || true
podman rm "$PROXY_NAME" 2>/dev/null || true

# Start the proxy sidecar
echo "Starting proxy sidecar..."
echo "Logs will be written to: $LOG_DIR"
podman run -d \
  --name "$PROXY_NAME" \
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

# Run amp container sharing proxy's network namespace (transparent proxy)
echo "Starting amp container..."
podman run -it --rm \
  --network "container:$PROXY_NAME" \
  --env-file "${SCRIPT_DIR}/envfile" \
  -v "${SCRIPT_DIR}/list:$HOME/list" \
  -v "$HOME/.config/:$HOME/.config:z" \
  -v "$HOME/.amp/:$HOME/.amp/:z" \
  -v "$HOME/.local/:$HOME/.local/:z" \
  -v "$HOME/.cache/:$HOME/.cache:z" \
  -v "$HOME/dev:/worktree/" \
  --userns=keep-id:uid=1001 \
  amp_in_a_box "$@"

# Cleanup proxy on exit
echo "Stopping proxy..."
podman stop "$PROXY_NAME"
podman rm "$PROXY_NAME"

#!/bin/bash
set -e

# Run the container using Podman
# -it: Interactive terminal
# --rm: Remove container after exit
# --env-file: Load environment variables from envfile
# -v: Mount directories from host into container

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
AMP_PROJECT="${AMP_PROJECT:-$HOME/dev}"

# Parse command line arguments
while [[ $# -gt 0 ]]; do
  case $1 in
    --project)
      AMP_PROJECT="$2"
      shift 2
      ;;
    --help)
      echo "Usage: $0 [--project /path/to/project] [-- amp args...]"
      echo ""
      echo "Options:"
      echo "  --project PATH    Project directory to mount at /worktree (default: $HOME/dev)"
      echo ""
      echo "Environment variables:"
      echo "  AMP_PROJECT       Project directory (alternative to --project)"
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

if [[ ! -d "$AMP_PROJECT" ]]; then
  echo "ERROR: Project directory does not exist: $AMP_PROJECT"
  exit 1
fi

AMP=/home/ampy/
podman run -it --rm \
  --env-file "${SCRIPT_DIR}/envfile" \
  -v "$HOME/.config/:$AMP/.config:z"\
  -v "$HOME/.amp/:$AMP/.amp/:z"\
  -v "$HOME/.local/:$AMP/.local/:z" \
  -v "$HOME/.cache/:$AMP/.cache:z"\
  -v "$AMP_PROJECT:/worktree/:z"\
  --userns=keep-id:uid=1001 \
  amp_in_a_box "$@"
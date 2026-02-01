#!/bin/bash
set -e

# Run the container using Podman
# -it: Interactive terminal
# --rm: Remove container after exit
# --env-file: Load environment variables from envfile
# -v: Mount current directory to /app inside container
# -w: Set working directory to /app
# /home/njl/.local/share/amp
#
#ls: cannot access '/etc/ssl/certs/a148a8a3.0': No such file or directory
#ls: cannot access '/home/njl/.amp/file-changes/T-019c16e6-ee15-77c3-b4d1-5c4e8d3ab78b': No such file or directory
#ls: cannot access '/home/njl/.cache/amp/logs/cli.log': No such file or directory
#ls: cannot access '/home/njl/.config/amp/settings.json': No such file or directory
#ils: cannot access '/home/njl/.local/share/amp/history.jsonl.lock': No such file or directory
#ls: cannot access '/home/njl/.local/share/amp/session.json.amptmp': No such file or directory0#
podman run -it --rm \
  --env-file ./envfile \
  -v "./list:$HOME/list" \
  -v "$HOME/.config/:$HOME/.config:z"\
  -v "$HOME/.amp/:$HOME/.amp/:z"\
  -v "$HOME/.local/:$HOME/.local/:z" \
  -v "$HOME/.cache/:$HOME/.cache:z"\
  -v "$HOME/dev:/worktree/"\
  --userns=keep-id:uid=1001 \
  amp_in_a_box "$@"

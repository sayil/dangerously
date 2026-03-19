#!/bin/bash
SCRIPT_DIR="$(dirname "$(readlink -f "$0")")"

docker build -t claude-sandbox "$SCRIPT_DIR"
docker run -it \
  -v $(pwd):/workspace \
  -v ~/.claude.json:/home/claude/.claude.json \
  claude-sandbox bash -c '
    echo "Running inside container: $HOSTNAME | User: $(whoami)"
    echo "File system changes are restricted to /workspace."
    claude --dangerously-skip-permissions
  '
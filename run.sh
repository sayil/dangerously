#!/bin/bash
docker build -t claude-sandbox .
docker run -it \
  -v $(pwd):/workspace \
  -v ~/.claude.json:/home/claude/.claude.json \
  claude-sandbox bash -c '
    echo "Claude Code is running inside container: $HOSTNAME | User: $(whoami)"
    echo "File system changes are restricted to /workspace."
    claude --dangerously-skip-permissions
  '
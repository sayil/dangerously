#!/bin/bash

# Check Docker is installed
if ! command -v docker &> /dev/null; then
  echo "Error: Docker is not installed. https://docker.com"
  exit 1
fi

# Check Docker is running
if ! docker info &> /dev/null; then
  echo "Error: Docker is not running. Please start Docker and try again."
  exit 1
fi

# Check Claude credentials exist
if [ ! -f ~/.claude.json ]; then
  echo "Error: Claude credentials not found."
  echo "Install Claude Code and authenticate first:"
  echo "  npm install -g @anthropic-ai/claude-code"
  echo "  claude"
  exit 1
fi

SCRIPT_DIR="$(cd "$(dirname "$0")" && cd "$(readlink "$0" | xargs dirname)" && pwd)"

docker build -t claude-sandbox "$SCRIPT_DIR"
docker run -it \
  -v $(pwd):/workspace \
  -v ~/.claude.json:/home/claude/.claude.json \
  claude-sandbox bash -c '
    echo "Running inside container: $HOSTNAME | User: $(whoami)"
    echo "File system changes are restricted to /workspace."
    claude --dangerously-skip-permissions
  '
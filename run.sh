#!/bin/bash

# Handle --setup flag to force re-run OAuth setup
FORCE_SETUP=false
if [[ "$1" == "--setup" ]]; then
  FORCE_SETUP=true
fi

# Auto-load token from shell profile if it exists (extract value without sourcing entire profile)
if [[ "$OSTYPE" == "darwin"* ]] && [ -z "$CLAUDE_CODE_OAUTH_TOKEN" ]; then
  for profile in ~/.zshrc ~/.bash_profile ~/.bashrc; do
    if [ -f "$profile" ]; then
      token_line=$(grep "export CLAUDE_CODE_OAUTH_TOKEN=" "$profile" 2>/dev/null | tail -1)
      if [ -n "$token_line" ]; then
        export CLAUDE_CODE_OAUTH_TOKEN=$(echo "$token_line" | sed 's/export CLAUDE_CODE_OAUTH_TOKEN=//' | sed 's/"//g' | sed "s/'//g")
        break
      fi
    fi
  done
fi

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
if [ ! -f ~/.claude.json ] || [ ! -d ~/.claude ]; then
  echo "Error: Claude credentials not found."
  echo "Install Claude Code and authenticate first:"
  echo "  npm install -g @anthropic-ai/claude-code"
  echo "  claude"
  exit 1
fi

# Platform-specific auth setup
AUTH_FLAGS=()
if [[ "$OSTYPE" == "darwin"* ]]; then
  if [ -z "$CLAUDE_CODE_OAUTH_TOKEN" ] || [ "$FORCE_SETUP" = true ]; then
    if [ "$FORCE_SETUP" = true ]; then
      echo "⚙️  Re-running macOS OAuth setup"
    else
      echo "⚠️  First-time macOS setup required"
    fi
    echo ""
    echo "Claude Code on macOS stores credentials in the Keychain, which Docker"
    echo "containers cannot access. We need to extract your OAuth token."
    echo ""
    read -p "Run setup now? (y/n) " -n 1 -r
    echo
    echo ""

    if [[ ! $REPLY =~ ^[Yy]$ ]]; then
      echo "Setup cancelled. To run setup later, use:"
      echo "  dangerously --setup"
      echo ""
      echo "Or to set up manually:"
      echo "  1. Run: claude setup-token"
      echo "  2. Add to your shell profile: export CLAUDE_CODE_OAUTH_TOKEN=\"your-token\""
      echo "  3. Run: source ~/.zshrc"
      exit 1
    fi

    # Detect shell profile
    if [ -f ~/.zshrc ]; then
      PROFILE=~/.zshrc
    elif [ -f ~/.bash_profile ]; then
      PROFILE=~/.bash_profile
    elif [ -f ~/.bashrc ]; then
      PROFILE=~/.bashrc
    else
      PROFILE=~/.zshrc
    fi

    echo "Generating OAuth token..."
    echo ""
    claude setup-token
    echo ""

    read -p "Paste the token here: " token

    # Strip bracketed paste mode delimiters and whitespace
    token=$(echo "$token" | sed 's/\x1b\[200~//g' | sed 's/\x1b\[201~//g' | sed 's/\^?\[\[200~//g' | sed 's/\^?\[\[201~//g' | xargs)

    if [ -z "$token" ]; then
      echo "Error: No token provided"
      exit 1
    fi

    echo ""
    echo "Saving to $PROFILE..."

    # Check if already exists
    if grep -q "CLAUDE_CODE_OAUTH_TOKEN" "$PROFILE" 2>/dev/null; then
      # Remove old line
      sed -i '' '/CLAUDE_CODE_OAUTH_TOKEN/d' "$PROFILE"
    fi

    echo "export CLAUDE_CODE_OAUTH_TOKEN=\"$token\"" >> "$PROFILE"
    export CLAUDE_CODE_OAUTH_TOKEN="$token"

    echo ""
    echo "✅ Setup complete! Token saved to $PROFILE"
    echo "   You're all set - dangerously will automatically load it from now on."
    echo ""
    echo "   To update your token later, run: dangerously --setup"
    echo ""
  fi
  AUTH_FLAGS+=(-e CLAUDE_CODE_OAUTH_TOKEN="$CLAUDE_CODE_OAUTH_TOKEN")
else
  AUTH_FLAGS+=(-v ~/.claude/.credentials.json:/home/claude/.claude/.credentials.json)
fi

SCRIPT_DIR="$(cd "$(dirname "$0")" && cd "$(readlink "$0" | xargs dirname)" && pwd)"

docker build -t agent-sandbox "$SCRIPT_DIR"

# Copy Claude settings to temp directory to avoid Docker Desktop home directory warning
TEMP_CLAUDE_DIR=$(mktemp -d)
trap "rm -rf $TEMP_CLAUDE_DIR" EXIT
cp ~/.claude.json "$TEMP_CLAUDE_DIR/" 2>/dev/null || true
cp -r ~/.claude "$TEMP_CLAUDE_DIR/" 2>/dev/null || true

# Docker Compose integration: network Claude with project services if compose file exists
NETWORK_FLAGS=()

if [ -f "docker-compose.yml" ] || [ -f "docker-compose.yaml" ]; then
  echo "Found docker-compose file — starting services..."
  docker compose up -d
  COMPOSE_PROJECT=$(docker compose config 2>/dev/null | awk '/^name:/{print $2; exit}')
  if [ -n "$COMPOSE_PROJECT" ]; then
    COMPOSE_NETWORK=$(docker network ls \
      --filter "label=com.docker.compose.project=$COMPOSE_PROJECT" \
      --filter "label=com.docker.compose.network=default" \
      --format "{{.Name}}" 2>/dev/null)
    if [ -n "$COMPOSE_NETWORK" ]; then
      NETWORK_FLAGS+=(--network "$COMPOSE_NETWORK")
      echo "Joined Docker Compose network: $COMPOSE_NETWORK"
    fi
  fi
fi

docker run -it \
  -v "$(pwd):/workspace" \
  -v "$TEMP_CLAUDE_DIR:/tmp/claude_host" \
  "${AUTH_FLAGS[@]}" \
  "${NETWORK_FLAGS[@]}" \
  agent-sandbox bash -c '
    cp /tmp/claude_host/.claude.json /home/claude/.claude.json 2>/dev/null || true
    cp -r /tmp/claude_host/.claude/. /home/claude/.claude/ 2>/dev/null || true
    echo "Running inside container: $HOSTNAME | User: $(whoami)"
    echo "File system changes are restricted to /workspace."
    claude --dangerously-skip-permissions
  '
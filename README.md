# dangerously

Run Claude Code autonomously in an isolated Docker container.

Claude Code's `--dangerously-skip-permissions` flag lets agents act without interruption — 
but Anthropic warns you to only use it inside a sandboxed environment. `dangerously` spins 
up that sandbox for you.

## Requirements

- Docker
- Claude Code installed and authenticated on your machine
  - `npm install -g @anthropic-ai/claude-code`
  - Run `claude` once and complete login before using this tool

## Install

\```
npm install -g dangerously
\```

## Usage

Navigate to your project folder and run:

\```
dangerously
\```

Claude Code launches inside an isolated Docker container. File system changes are restricted 
to your current directory. Your host machine stays safe.

## How it works

- Runs Claude Code in a fresh Docker container per session
- Mounts your current directory as the working directory
- Passes your Claude credentials from `~/.claude.json` into the container
- Runs as a non-root user with `--dangerously-skip-permissions` enabled
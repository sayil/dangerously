# dangerously

Run Claude Code autonomously in an isolated Docker container.

Claude Code's `--dangerously-skip-permissions` flag lets agents act without interruption —
but Anthropic warns you to only use it inside a sandboxed environment. `dangerously` spins
up that sandbox for you.

## Prerequisites

- Docker (https://docker.com)
- Claude Code installed and authenticated on your machine
  - `npm install -g @anthropic-ai/claude-code`
  - Run `claude` once and complete login

**macOS users:** The first time you run `dangerously`, you'll be prompted to complete a one-time OAuth setup (Claude Code on macOS stores credentials in the Keychain which Docker containers cannot access). Just follow the prompts — it takes 30 seconds and you'll never need to do it again.

If you need to update your token (e.g., you pasted the wrong one), run:
```bash
dangerously --setup
```

## Install

```
npm install -g dangerously
```

## Usage

Navigate to your project folder and run:

```
dangerously
```

Claude Code launches inside an isolated Docker container. File system changes are restricted
to your current directory. Your host machine stays safe.

## How it works

- Runs Claude Code in a fresh Docker container per session
- Mounts your current directory as the working directory
- Passes your Claude credentials from `~/.claude.json` into the container
- Runs as a non-root user with `--dangerously-skip-permissions` enabled

## Voice support

The `/voice` command works out of the box — SoX is pre-installed in the container.

## Docker Compose integration

If your project has a `docker-compose.yml`, running `dangerously` will automatically start
your services and join Claude's container to the same Docker network. This means Claude can
reach your databases, caches, queues, and other services by their service names — exactly as
your app would.

```
my-project/
├── docker-compose.yml   # defines postgres, redis, etc.
├── src/
└── ...

$ cd my-project
$ dangerously
# Services start, Claude joins the network, can connect to postgres:5432, redis:6379, etc.
```

No changes to your `docker-compose.yml` are required. If no compose file is present,
behaviour is unchanged.

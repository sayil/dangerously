FROM node:20
RUN apt-get update && apt-get install -y sox && rm -rf /var/lib/apt/lists/*
RUN npm install -g @anthropic-ai/claude-code
RUN useradd -m claude
WORKDIR /workspace
RUN chown claude:claude /workspace
USER claude

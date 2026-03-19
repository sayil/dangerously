FROM node:20
RUN npm install -g @anthropic-ai/claude-code
RUN useradd -m claude
WORKDIR /workspace
RUN chown claude:claude /workspace
USER claude

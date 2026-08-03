FROM node:24-bookworm-slim

RUN apt-get update \
  && apt-get install -y --no-install-recommends clamav ca-certificates tini \
  && freshclam \
  && rm -rf /var/lib/apt/lists/*

WORKDIR /app
COPY package.json ./
COPY src ./src

ENV NODE_ENV=production PORT=8080
USER node
EXPOSE 8080
ENTRYPOINT ["/usr/bin/tini", "--"]
CMD ["node", "src/server.mjs"]

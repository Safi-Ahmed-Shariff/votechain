FROM node:20-alpine AS builder

WORKDIR /build

COPY package.json .

RUN npm install --production

FROM node:20-alpine

RUN apk --no-cache add curl

WORKDIR /app

COPY --from=builder /build/node_modules ./node_modules
COPY index.js .
COPY package.json .

RUN adduser -D -s /bin/sh votechain && \
    chown -R votechain:votechain /app
USER votechain

EXPOSE 8003

HEALTHCHECK --interval=30s --timeout=10s --retries=3 \
    CMD curl -f http://localhost:8003/health || exit 1

CMD ["node", "index.js"]

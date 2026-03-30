FROM golang:1.22-alpine AS builder

WORKDIR /build

COPY go.mod .
COPY main.go .

RUN go mod tidy && \
    CGO_ENABLED=0 GOOS=linux go build -o auth-service .

FROM alpine:3.19

RUN apk --no-cache add curl

WORKDIR /app

COPY --from=builder /build/auth-service .

RUN adduser -D -s /bin/sh votechain && \
    chown votechain:votechain /app/auth-service
USER votechain

EXPOSE 8002

HEALTHCHECK --interval=30s --timeout=10s --retries=3 \
  CMD curl -f http://localhost:8002/health || exit 1

CMD ["./auth-service"]

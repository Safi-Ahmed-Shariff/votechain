FROM golang:1.26.1-alpine3.22 AS builder

WORKDIR /build

COPY go.mod .
COPY main.go .

RUN go mod tidy && \
    CGO_ENABLED=0 GOOS=linux go build -o auth-service .

FROM alpine:3.22

WORKDIR /app

COPY --from=builder /build/auth-service .

RUN adduser -D -s /bin/sh votechain && \
    chown votechain:votechain /app/auth-service
USER votechain

EXPOSE 8002

HEALTHCHECK --interval=30s --timeout=10s --retries=3 \
    CMD wget -qO- http://localhost:8002/health || exit 1

CMD ["./auth-service"]

FROM golang:1.24.1-alpine AS builder

WORKDIR /app

COPY go.mod ./
RUN go mod download

COPY . ./
RUN go build -o app

# ----------------------------------------

FROM alpine:latest

# Instala o Docker CLI
RUN apk add --no-cache docker-cli

WORKDIR /root/

COPY --from=builder /app/app .

ENV PORT=8080
EXPOSE 8080

CMD ["./app"]

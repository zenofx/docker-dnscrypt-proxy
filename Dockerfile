FROM golang:latest as builder
ARG VERSION=master
WORKDIR /go/src
RUN set -x \
	&& git clone https://github.com/jedisct1/dnscrypt-proxy.git \
	&& cd dnscrypt-proxy \
	&& git checkout ${VERSION} -b build \
	&& cd dnscrypt-proxy \
	&& env CGO_ENABLED=0 GOOS=linux GOARCH=amd64 go build -ldflags="-s -w" \
	&& mkdir -p /tmp/dnscrypt-proxy/config \
	&& cp dnscrypt-proxy /tmp/dnscrypt-proxy \
	&& cp example-* /tmp/dnscrypt-proxy/config

#FROM gcr.io/distroless/base
FROM alpine:latest

RUN set -x \
	&& apk --no-cache add ca-certificates bind-tools

VOLUME /config
COPY --from=builder /tmp/dnscrypt-proxy/dnscrypt-proxy /app/
COPY --from=builder /tmp/dnscrypt-proxy/config/* /config/

EXPOSE 53/tcp 53/udp

HEALTHCHECK --interval=60s --timeout=10s --start-period=60s \
	CMD dig +timeout=10 +tries=1 +short @127.0.0.1 -p 53 localhost

USER nobody
WORKDIR /app
ENTRYPOINT [ "./dnscrypt-proxy" ]
CMD [ "-config", "/config/dnscrypt-proxy.toml" ]

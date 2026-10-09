FROM debian:bookworm-slim

ARG DEBIAN_FRONTEND=noninteractive

RUN apt-get update && apt-get install -y --no-install-recommends \
    ca-certificates \
    wget \
    && rm -rf /var/lib/apt/lists/*

RUN wget -q https://github.com/DNSCrypt/doh-server/releases/download/0.10.0/doh-proxy_0.10.0-1_amd64.deb \
    -O /tmp/doh-proxy.deb \
    && apt-get update \
    && apt-get install -y --no-install-recommends /tmp/doh-proxy.deb \
    && rm -f /tmp/doh-proxy.deb \
    && rm -rf /var/lib/apt/lists/*

EXPOSE 3000

ENTRYPOINT ["doh-proxy"]
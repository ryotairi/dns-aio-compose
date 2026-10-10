#!/bin/sh
set -e

mkdir -p /tmp/rules
cat /config/cloaking/*.txt > /tmp/cloaking.txt
cat /config/forwarding/*.txt > /tmp/forwarding.txt

exec dnscrypt-proxy -config /config/dnscrypt-proxy.toml
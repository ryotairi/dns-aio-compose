# DNSCrypt Compose

A multi-service DNS stack powered by Docker Compose, combining **DNSCrypt**, **OpenNIC**, **ALFIS**, **DoH**, and **DoT** into a single, self-contained privacy-resolving network.

| Service | Role |
|---|---|
| **DNSCrypt** | Primary DNS forwarder (plain DNS on port 53), supports forwarding + cloaking rules |
| **OpenNIC** | OpenNIC TLD resolver (`.bbs`, `.chan`, `.geek`, etc.) |
| **ALFIS** | Alternative DNS root (`.anon`, `.btn`, `.ygg`, etc.) |
| **DoH** | DNS-over-HTTPS proxy (forwards to DNSCrypt) |
| **DoT** | DNS-over-TLS proxy (forwards to DNSCrypt) |

## Getting Started

### 1. Clone and configure

```bash
git clone https://source.extera.xyz/rustyraven/dns-aio-compose.git
cd dnscrypt-compose
cp .env.example .env
```

Edit `.env` to set ports and the DoH hostname (`PLAIN_DNS_PORT`, `DOT_PORT`, `DOH_PORT`, `DOH_HOST`, `DOH_LISTEN_HOST`).

### 2. Add TLS certificates (for DoT)

Place `fullchain.pem` and `privkey.pem` in `./certs/`. Certificates and `.env` are gitignored.

### 3. Start

```bash
docker compose up -d
```

On startup, the DNSCrypt container concatenates all rule fragments from `config-dnscrypt/cloaking/` and `config-dnscrypt/forwarding/` into `/tmp/cloaking.txt` and `/tmp/forwarding.txt`, then launches dnscrypt-proxy.

## Custom rules (forwarding & cloaking)

Rules are stored as separate files in two directories. **Never edit the base files** - create a `*.user.txt` file instead (e.g. `2.user.txt`). Files matching `*.user.txt` are gitignored, so your personal rules stay out of the repo.

### Forwarding rules - `config-dnscrypt/forwarding/`

Route domains or whole TLDs to a specific DNS server. Format: `<domain> <ip>`.

```
# default forwarders for alternative TLDs (base 1.txt)
bbs 172.30.0.3
anon 172.30.0.4

# your rule
example.net 192.168.1.10
```

### Cloaking rules - `config-dnscrypt/cloaking/`

Override DNS responses locally: a domain name is "cloaked" to a fixed IP instead of its real address. Format: `<domain> <ip>`.

```
my-local.dev 127.0.0.1
tracker.example 0.0.0.0
```

### Applying changes

After adding or editing `user_*.txt` files, restart the stack - rules are rebuilt on startup:

```bash
docker compose restart dnscrypt
```

## Querying the stack

```bash
# Plain DNS (default port 39053)
dig @127.0.0.1 -p 39053 example.com

# Alternative TLDs (OpenNIC / ALFIS, via forwarding rules)
dig @127.0.0.1 -p 39053 example.bbs
dig @127.0.0.1 -p 39053 example.anon

# DNS-over-TLS (default port 39054)
kdig -d @127.0.0.1 +tls-port=39054 example.com

# DNS-over-HTTPS (default port 39055)
curl -H "Accept: application/dns-json" "http://127.0.0.1:39055/dns-query?name=example.com&type=A"
```
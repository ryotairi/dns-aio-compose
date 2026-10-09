# DNSCrypt Compose

A multi-service DNS stack powered by Docker Compose, combining **DNSCrypt**, **OpenNIC**, **ALFIS**, **DoH**, and **DoT** into a single, self-contained privacy-resolving network.


| Service | IP (IPv4) | IP (IPv6) | Role |
|---|---|---|---|
| **DNSCrypt** | `172.30.0.2` | `fd12:3456:789a::2` | Primary DNS forwarder with DNSCrypt protocol support |
| **OpenNIC** | `172.30.0.3` | `fd12:3456:789a::3` | OpenNIC TLD resolver (`.bbs`, `.chan`, `.geek`, etc.) |
| **ALFIS** | `172.30.0.4` | `fd12:3456:789a::4` | Alternative DNS root (`.anon`, `.btn`, `.ygg`, etc.) |
| **DoH** (doh-server) | `172.30.0.5` | `fd12:3456:789a::5` | DNS-over-HTTPS proxy (forwarding to DNSCrypt) |
| **DoT** (AdGuard) | `172.30.0.6` | `fd12:3456:789a::6` | DNS-over-TLS proxy (forwarding to DNSCrypt) |

## Services

### DNSCrypt Proxy
- **Image:** [`klutchell/dnscrypt-proxy`](https://github.com/klutchell/dnscrypt-proxy-docker)
- **Config:** `./config-dnscrypt/dnscrypt-proxy.toml`
- The primary resolver. Exposes port `53` to the host. Supports **cloaking rules** and **forwarding rules**:
  - **Forwarding rules** (`config-dnscrypt/forwarding.txt`) — OpenNIC and ALFIS TLDs are forwarded to their respective containers.
  - **Cloaking rules** (`config-dnscrypt/cloaking.txt`) — local overrides for specific domains.

### OpenNIC Resolver
- **Image:** [`klutchell/dnscrypt-proxy`](https://github.com/klutchell/dnscrypt-proxy-docker)
- **Config:** `./config-opennic/dnscrypt-proxy.toml`
- Configured to use OpenNIC-specific resolvers (`ibksturm`, `libredns`). Resolves OpenNIC alternative TLDs (`.bbs`, `.chan`, `.cyb`, `.dyn`, `.geek`, `.gopher`, `.indy`, `.libre`, `.neo`, `.null`, `.o`, `.oss`, `.oz`, `.parody`, `.pirate`).

### ALFIS Resolver
- **Image:** [`ghcr.io/revertron/alfis`](https://github.com/Revertron/ALFIS)
- Provides resolution for the **ALFIS** alternative DNS namespace (`.anon`, `.btn`, `.conf`, `.index`, `.merch`, `.mirror`, `.mob`, `.screen`, `.srv`, `.ygg`).
- State is persisted in a named volume: `alfis-cache`.

### DNS-over-HTTPS (DoH)
- **Build:** `./doh-server/Dockerfile`
- Uses the official [DNSCrypt/doh-server](https://github.com/DNSCrypt/doh-server) binary (`doh-proxy`).
- Accepts HTTPS queries on `${DOH_PORT}` and forwards them as plain DNS to the DNSCrypt container (`172.30.0.2:53`).

### DNS-over-TLS (DoT)
- **Image:** [`adguard/dnsproxy`](https://github.com/AdguardTeam/dnsproxy)
- Wraps DNS queries in TLS on port `853`.
- Requires TLS certificate files in `./certs/` (`fullchain.pem`, `privkey.pem`).
- Forwards upstream to the DNSCrypt container (`172.30.0.2:53`).

## Prerequisites

- [Docker](https://docs.docker.com/get-docker/) (with Compose V2)
- A **TLS certificate** for DoT support (place `fullchain.pem` and `privkey.pem` in `./certs/`)

## Getting Started

### 1. Clone the repository

```bash
git clone https://source.extera.xyz/rustyraven/dns-aio-compose.git
cd dnscrypt-compose
```

### 2. Configure environment variables

Copy the example environment file and edit it:

```bash
cp .env.example .env
```

| Variable | Default | Description |
|---|---|---|
| `PLAIN_DNS_PORT` | `39053` | Host port for plain DNS (mapped to container port 53) |
| `DOT_PORT` | `39054` | Host port for DNS-over-TLS |
| `DOH_HOST` | `dns.example.com` | The public hostname of your DoH server (used for HTTPS SNI & Host header) |
| `DOH_LISTEN_HOST` | `0.0.0.0` | Host address for DNS-over-HTTPS |
| `DOH_PORT` | `39055` | Host port for DNS-over-HTTPS |

### 3. Add TLS certificates (for DoT)

Place your certificate chain and private key in the `certs/` directory:

```
certs/
├── fullchain.pem
└── privkey.pem
```

> **Note:** `certs/*.pem` and `/.env` are gitignored by default.

### 4. Start the stack

```bash
docker compose up -d
```

Check the logs to verify everything started correctly:

```bash
docker compose logs -f
```

## Usage

### Querying the DNS stack

Once running, you can query any of the exposed ports:

```bash
# Plain DNS (default port 39053)
dig @127.0.0.1 -p 39053 example.com

# DNS-over-TLS (default port 39054)
kdig -d @127.0.0.1 +tls-port=39054 example.com

# DNS-over-HTTPS (default port 39055)
curl -H "Accept: application/dns-json" "http://127.0.0.1:39055/dns-query?name=example.com&type=A"
```

### Resolving alternative TLDs

The forwarding rules in `config-dnscrypt/forwarding.txt` automatically route alternative TLDs to the correct backend:

```bash
# OpenNIC TLDs (.bbs, .chan, .geek, etc.)
dig @127.0.0.1 -p 39053 example.bbs

# ALFIS TLDs (.anon, .btn, .ygg, etc.)
dig @127.0.0.1 -p 39053 example.anon
```

## Configuration Reference

### DNSCrypt Proxy (`config-dnscrypt/dnscrypt-proxy.toml`)

| Setting | Value | Notes |
|---|---|---|
| `listen_addresses` | `['0.0.0.0:53']` | Listen inside the container on port 53 |
| `block_ipv6` | `false` | Allows AAAA queries |
| `cloaking_rules` | `/config/cloaking.txt` | Local DNS override file |
| `forwarding_rules` | `/config/forwarding.txt` | TLD-based forwarding rules |
| Sources | Public resolvers + relays | Fetched from the official DNSCrypt resolvers list |

### OpenNIC Proxy (`config-opennic/dnscrypt-proxy.toml`)

| Setting | Value | Notes |
|---|---|---|
| `server_names` | `['ibksturm', 'libredns']` | Uses these specific OpenNIC-compatible resolvers |
| `cloaking_rules` | `/config/cloaking.txt` | Local overrides (currently empty) |
| Sources | OpenNIC resolver list | Fetched from the official DNSCrypt OpenNIC resolver list |

### Forwarding Rules

| TLD | Destination | Namespace |
|---|---|---|
| `.bbs`, `.chan`, `.cyb`, `.dyn`, `.geek`, `.gopher`, `.indy`, `.libre`, `.neo`, `.null`, `.o`, `.oss`, `.oz`, `.parody`, `.pirate` | `172.30.0.3` (OpenNIC) | OpenNIC alternative roots |
| `.anon`, `.btn`, `.conf`, `.index`, `.merch`, `.mirror`, `.mob`, `.screen`, `.srv`, `.ygg` | `172.30.0.4` (ALFIS) | ALFIS alternative roots |

## Customization

### Adding cloaking rules

Edit `config-dnscrypt/cloaking.txt` (or `config-opennic/cloaking.txt`) to map domains to specific IPs:

```
# Format: example.com 1.2.3.4
my-local.dev 127.0.0.1
```

Then restart the stack:

```bash
docker compose restart dnscrypt
```

### Changing upstream resolvers

Update `server_names` in `config-dnscrypt/dnscrypt-proxy.toml` or `config-opennic/dnscrypt-proxy.toml` with your preferred resolvers. See the [public resolvers list](https://github.com/DNSCrypt/dnscrypt-resolvers) for options.

## File Structure

```
.
├── .env                          # User-specific environment variables (gitignored)
├── .env.example                  # Environment variable template
├── .gitignore
├── docker-compose.yml            # Service definitions & network
├── README.md                     # This file
├── certs/                        # TLS certificates (gitignored .pem files)
│   ├── fullchain.pem
│   └── privkey.pem
├── config-dnscrypt/              # Primary DNSCrypt resolver config
│   ├── dnscrypt-proxy.toml
│   ├── cloaking.txt
│   └── forwarding.txt
├── config-opennic/               # OpenNIC resolver config
│   ├── dnscrypt-proxy.toml
│   └── cloaking.txt
└── doh-server/                   # DNS-over-HTTPS server
    └── Dockerfile
```
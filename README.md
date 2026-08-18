# Bit Core Docker (B1T)

This project provides a Docker image for Bit Core. It downloads the Linux binaries from the provided release, installs system dependencies, and starts `bitd` with a persistent data directory.

- Upstream Release: [`Bit Core v4.0.0.0 — restore peer discovery (Linux)`](https://github.com/OnlyPW/Bit-core/releases/download/v4.0.0.0/Bit-v4.0.0.0.tar.gz)
- Repository (initially empty): [`Bitcore-docker-B1T-`](https://github.com/OnlyPW/Bitcore-docker-B1T-.git)

## Features
- Minimal base container (Debian slim)
- Installation of necessary runtime libraries (Boost, OpenSSL, ZMQ, Berkeley DB, etc.)
- Automatic creation of a default `bit.conf` (with random RPC password if not set)
- Configurable UID/GID (PUID/PGID) for file permissions
- Persistent data storage under `/data`
- `docker-compose.yml` for quick startup

## Quick Start

### Automatic Installation

**Windows:**
```cmd
install.bat
```

**Linux/macOS:**
```bash
chmod +x install.sh
./install.sh
```

### Manual Installation

Prerequisites: Docker and Docker Compose.

```bash
# Build image
docker compose build

# Start node (mainnet)
docker compose up -d

# Follow logs
docker compose logs -f
```

By default, P2P port 33317 (chain default) is exposed, and RPC port 45873 (chain default) is published to localhost as 127.0.0.1:8332. The data directory is stored in the local `./data` directory.

## Configuration

Important environment variables (see `docker-compose.yml`):

- `NETWORK`: `mainnet` (default), `testnet` or `regtest`
- `RPC_USER`: Username for RPC
- `RPC_PASSWORD`: Password for RPC (if not set, randomly generated)
- `RPC_ALLOW_IP`: RPC access (CIDR), default `0.0.0.0/0`
- `PUID`, `PGID`: Owner of the data directory

On first startup, a configuration file is created under `/data/bit.conf` if it doesn't exist. You can modify this file as needed and restart the container.

## Management Scripts

### Windows
```cmd
manage.bat
```

### Linux/macOS
```bash
chmod +x manage.sh
./manage.sh
```

The management scripts provide an interactive menu for:
- Starting/stopping/restarting Bit Core
- Viewing logs
- Checking status
- Updating configuration
- Cleaning data (with confirmation)

## Manual CLI Usage

Examples (container must be running):

```bash
# Query block height via RPC
docker exec -it bitcore bit-cli -conf=/data/bit.conf -datadir=/data getblockcount

# Stop node
docker compose down
```

## Dependency Notes

The image installs common runtime libraries required for Bitcoin-derived nodes (Boost, libevent, ZMQ, Berkeley DB, OpenSSL, libsodium, miniupnpc). If the provided binaries require additional distribution-specific libraries, please report or create a PR.

## License

Unless otherwise specified, MIT.

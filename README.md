# Bit Core Docker (B1T)

This project provides a Docker image for Bit Core. It downloads the Linux binaries from the provided release, installs system dependencies, and starts `bitd` with a persistent data directory.

- Upstream Release: [`Bit v3 (Linux)`](https://github.com/bittoshimoto/Bit/releases/download/Bit.v3/bit.v3.tar.gz)
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

By default, ports 8333 (P2P) and 8332 (RPC) are exposed. The data directory is stored in the local `./data` directory.

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

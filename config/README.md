# Bit Core Configuration

This directory contains configuration templates for Bit Core.

## Files

- `bit.conf` - Main configuration template for Bit Core

## Usage

1. The `bit.conf` template is automatically copied to the data directory on first startup
2. Environment variables in `docker-compose.yml` will override template values:
   - `RPC_USER` - RPC username
   - `RPC_PASSWORD` - RPC password (auto-generated if not set)
   - `RPC_ALLOW_IP` - Allowed RPC IP ranges
   - `NETWORK` - Network mode (mainnet/testnet/regtest)

## Customization

You can modify the `bit.conf` template to add additional Bit Core settings. The template includes:

- Basic server settings
- RPC configuration
- Network settings
- Performance tuning options
- Optional testnet/regtest settings

## Network Modes

- **mainnet** (default) - Production network
- **testnet** - Test network
- **regtest** - Local testing network

To switch networks, set the `NETWORK` environment variable in `docker-compose.yml`.

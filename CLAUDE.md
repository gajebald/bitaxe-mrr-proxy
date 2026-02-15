# CLAUDE.md

Project context for AI-assisted development with Claude Code.

## Project Overview

**bitaxe-mrr-proxy** is a lightweight, transparent Stratum V1 proxy that sits between Bitaxe miners (e.g. Bitaxe Gamma 601) and MiningRigRentals pool servers. It forwards all TCP traffic bidirectionally without parsing or modifying any Stratum messages. Its purpose is to avoid pool redirect issues that can occur when MiningRigRentals sends `client.reconnect` commands.

## Architecture

```
Bitaxe Miner  ←→  Proxy (asyncio TCP server on 0.0.0.0:3333)  ←→  MiningRigRentals Pool
```

The proxy uses Python's `asyncio` to handle concurrent miner connections. For each incoming miner connection, it opens a connection to the remote pool and spawns two forwarding tasks (miner→pool and pool→miner) via `asyncio.gather`.

## File Structure

```
stratum_minimal_proxy.py   # Main proxy application (~74 lines)
setup.sh                   # Interactive setup script (installs to /usr/local/bin, creates systemd service)
README.md                  # User-facing documentation
CLAUDE.md                  # This file
```

## Running the Proxy

```bash
python3 stratum_minimal_proxy.py \
  --listen-port 3333 \
  --pool-host eu-de02.miningrigrentals.com \
  --pool-port 3333 \
  --user youruser.worker \
  --passw x
```

No external dependencies are needed — only the Python 3.8+ standard library (`asyncio`, `argparse`, `logging`).

## Key Implementation Details

- **`handle_client()`** — accepts a miner connection, opens a pool connection, runs bidirectional forwarding via `asyncio.gather`
- **`forward()`** — reads from one stream in 4096-byte chunks and writes to the other; handles errors and closes connections gracefully
- **`main()`** — parses CLI args, starts the asyncio TCP server on `0.0.0.0`
- The `--user` and `--passw` CLI arguments are required but **not actively used** by the proxy. They exist for documentation/reference in the systemd service file. The miner sends its own credentials through the transparent relay.

## Code Conventions

- Python 3.8+ with asyncio (no external dependencies)
- Logging uses emoji prefixes for visual distinction in logs (e.g. `🧍` connection, `⛓️` pool linked, `⚠️` warning, `❌` error, `🔌` disconnect, `✅` ready)
- `logging.basicConfig` with `INFO` level and timestamped format
- setup.sh uses bash with `set -e` and colored output

## Testing

There is no automated test suite. To verify the proxy works:

1. Start the proxy with valid pool parameters
2. Point a Bitaxe miner (or a Stratum test client) at the proxy
3. Check logs for successful connection messages (`✅`, `🧍`, `⛓️`)

## Deployment

The `setup.sh` script handles production deployment:
- Copies the script to `/usr/local/bin/stratum_minimal_proxy.py`
- Creates a systemd service at `/etc/systemd/system/bitaxe-mrr-proxy.service`
- Enables auto-start on boot with automatic restart on failure (5s delay)
- Target platform: Linux with systemd (Raspberry Pi is the primary target)

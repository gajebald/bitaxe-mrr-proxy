# bitaxe-mrr-proxy

A lightweight Stratum V1 proxy for Bitaxe miners (e.g., Bitaxe Gamma 601) and MiningRigRentals. It forwards Stratum traffic transparently and helps avoid pool redirect issues. The implementation uses Python 3 with asyncio for efficient asynchronous operation.

## Features

- Transparent Stratum V1 protocol forwarding
- Minimal resource usage (ideal for Raspberry Pi)
- No external dependencies (Python standard library only)
- Automatic reconnection on failure
- Systemd service integration for auto-start

## Requirements

- Python 3.8 or newer
- Linux with systemd (for automatic startup)
- Network connectivity to MiningRigRentals

## Quick Start (Automated)

The easiest way to install is using the setup script:

```bash
git clone https://github.com/gajebald/bitaxe-mrr-proxy.git
cd bitaxe-mrr-proxy
chmod +x setup.sh
./setup.sh
```

The script will:
- Check system requirements (Python 3.8+, systemd)
- Prompt for pool configuration
- Install the proxy to `/usr/local/bin/`
- Create and start a systemd service

## Manual Installation

### 1. Clone the repository

```bash
git clone https://github.com/gajebald/bitaxe-mrr-proxy.git
cd bitaxe-mrr-proxy
```

### 2. Test the proxy

No additional libraries are required. Run directly:

```bash
python3 stratum_minimal_proxy.py \
  --listen-port 3333 \
  --pool-host eu-de02.miningrigrentals.com \
  --pool-port 3333 \
  --user youruser.worker \
  --passw x
```

### 3. Configure as systemd service (optional)

Create `/etc/systemd/system/bitaxe-mrr-proxy.service`:

```ini
[Unit]
Description=Bitaxe MRR Proxy - Stratum V1 Mining Proxy
Documentation=https://github.com/gajebald/bitaxe-mrr-proxy
After=network-online.target
Wants=network-online.target

[Service]
Type=simple
User=YOUR_USERNAME
ExecStart=/usr/bin/python3 /usr/local/bin/stratum_minimal_proxy.py \
  --listen-port 3333 \
  --pool-host eu-de02.miningrigrentals.com \
  --pool-port 3333 \
  --user youruser.worker \
  --passw x
Restart=always
RestartSec=5
StandardOutput=journal
StandardError=journal

[Install]
WantedBy=multi-user.target
```

Replace `YOUR_USERNAME` with your Linux user (e.g. `pi`). If you used `setup.sh`, the script is already at `/usr/local/bin/stratum_minimal_proxy.py`. Otherwise adjust the path to where you cloned the repository.

Enable and start:

```bash
sudo systemctl daemon-reload
sudo systemctl enable bitaxe-mrr-proxy
sudo systemctl start bitaxe-mrr-proxy
```

## Command Line Arguments

| Argument | Required | Default | Description |
|----------|----------|---------|-------------|
| `--listen-port` | No | 3333 | Port for miners to connect to the proxy |
| `--pool-host` | Yes | - | MiningRigRentals server hostname |
| `--pool-port` | Yes | - | MiningRigRentals server port |
| `--user` | Yes | - | MRR username.worker (stored for reference, not actively used) |
| `--passw` | Yes | - | MRR password, usually `x` (stored for reference, not actively used) |

> **Note:** The `--user` and `--passw` arguments are required by the CLI but not actively used by the proxy. The proxy is a transparent TCP relay — your miner sends its own credentials directly through the connection to MiningRigRentals.

## MiningRigRentals Servers

Common server addresses:

| Region | Server Address |
|--------|----------------|
| Europe (Germany) | `eu-de02.miningrigrentals.com` |
| US East | `us-east01.miningrigrentals.com` |
| US West | `us-west01.miningrigrentals.com` |

Check MiningRigRentals documentation for the full list of available servers.

## Configuring Your Bitaxe

In the Bitaxe web interface:

1. **Pool URL**: Enter the IP address of your proxy device and the listen port
   Example: `192.168.1.100:3333`
2. **Username**: Your MiningRigRentals username with worker suffix
   Example: `youruser.worker1`
3. **Password**: Your MiningRigRentals password (usually `x`)

The proxy is a transparent relay — all Stratum V1 traffic (including authentication) is forwarded as-is between your miner and MiningRigRentals.

## Service Management

After installation with `setup.sh`, use these commands:

```bash
# Check service status
sudo systemctl status bitaxe-mrr-proxy

# View live logs
sudo journalctl -u bitaxe-mrr-proxy -f

# Restart the service
sudo systemctl restart bitaxe-mrr-proxy

# Stop the service
sudo systemctl stop bitaxe-mrr-proxy

# Disable auto-start
sudo systemctl disable bitaxe-mrr-proxy
```

## Uninstalling

To completely remove the proxy:

```bash
sudo systemctl stop bitaxe-mrr-proxy
sudo systemctl disable bitaxe-mrr-proxy
sudo rm /etc/systemd/system/bitaxe-mrr-proxy.service
sudo systemctl daemon-reload
sudo rm /usr/local/bin/stratum_minimal_proxy.py
```

## Troubleshooting

### Service won't start

Check logs for errors:
```bash
sudo journalctl -u bitaxe-mrr-proxy -n 50
```

### Connection refused

- Verify the proxy is running: `sudo systemctl status bitaxe-mrr-proxy`
- Check firewall settings allow connections on the listen port
- Ensure the Bitaxe is configured with the correct IP and port

### Pool redirect issues

MiningRigRentals may send `client.reconnect` messages to redirect miners to different ports. If you notice connection issues, check the logs for the new port number and update `--pool-port` accordingly.

### Python not found

Ensure Python 3.8+ is installed:
```bash
python3 --version
# If not installed:
sudo apt update && sudo apt install python3
```

## How It Works

The proxy operates as a transparent TCP relay:

```
Bitaxe Miner → [Proxy :3333] → MiningRigRentals Pool
                    ↑
              Bidirectional
              data forwarding
```

1. Miners connect to the proxy on the configured listen port
2. The proxy establishes a connection to MiningRigRentals
3. All Stratum V1 messages are forwarded bidirectionally
4. No message parsing or modification occurs

## Notes

- This proxy supports Stratum V1 only; Stratum V2 is not supported
- The proxy does not modify any mining data or inject its own credentials
- For multiple miners, a single proxy instance can handle many concurrent connections
- This project is provided as-is. Use at your own risk.

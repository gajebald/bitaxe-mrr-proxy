bitaxe-mrr-proxy

A simple Stratum proxy for Bitaxe Gamma 601 and MiningRigRentals. It forwards Stratum‑V1 traffic to MiningRigRentals and helps to avoid redirects. The implementation is based on Python 3 and asyncio.

## Installation

1. **Clone the repository**:

```bash
git clone https://github.com/gajebald/bitaxe-mrr-proxy.git
cd bitaxe-mrr-proxy
```

2. **Python dependencies**: No additional libraries are required; Python 3.8 or newer is sufficient. Optionally you can create a virtual environment:

```bash
python3 -m venv venv
source venv/bin/activate
```

## Usage

Start the proxy with the following parameters:

```bash
python3 stratum_minimal_proxy.py \
  --listen-port 3333 \
  --pool-host eu-de02.miningrigrentals.com \
  --pool-port 3333 \
  --user <YOUR_USERNAME.WORKER> \
  --passw <YOUR_PASSWORD>
```

- `--listen-port`: Port on which your Bitaxe miner will connect to the proxy (e.g. 3333).
- `--pool-host`: Address of the MiningRigRentals server (e.g. `eu-de02.miningrigrentals.com`).
- `--pool-port`: Port of the pool. MiningRigRentals can refer you via `client.reconnect` to another port; in that case adjust this value.
- `--user`: Your MiningRigRentals username including worker suffix (example: `<YOUR_USERNAME.WORKER>`).
- `--passw`: Password (with MRR usually `x`, or your individual worker password).

## Configure Bitaxe

In the Bitaxe web interface, enter the IP address of your Raspberry Pi as the pool address and the listen port, e.g. `192.168.178.60:3333`. Leave username and password empty, as the proxy forwards these automatically to MiningRigRentals.

## Autostart with systemd

To have the proxy start automatically after every reboot, set up a systemd service. Create a file `/etc/systemd/system/stratum-proxy.service` with the following content (adjust path and username as needed):

```ini
[Unit]
Description=Stratum Mining Proxy
After=network.target

[Service]
ExecStart=/usr/bin/python3 /home/pi/bitaxe-mrr-proxy/stratum_minimal_proxy.py \
  --listen-port 3333 \
  --pool-host eu-de02.miningrigrentals.com \
  --pool-port 3333 \
  --user <YOUR_USERNAME.WORKER> \
  --passw <YOUR_PASSWORD>
WorkingDirectory=/home/pi/bitaxe-mrr-proxy
User=pi
Restart=always

[Install]
WantedBy=multi-user.target
```

Then reload systemd, enable and start the service:

```bash
sudo systemctl daemon-reload
sudo systemctl enable stratum-proxy
sudo systemctl start stratum-proxy
```

## Notes

- MiningRigRentals may redirect you to a different port after connecting (using the `client.reconnect` Stratum message). If that happens, update `--pool-port` accordingly.
- This proxy is designed for Stratum V1 only; Stratum V2 is not supported.
- This project is provided as an example. Use at your own risk.

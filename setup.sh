#!/bin/bash
# Setup script for the Bitaxe MRR Proxy
# This script installs the stratum_minimal_proxy.py script and sets up a systemd service.
# It prompts for MiningRigRentals credentials and optional configuration parameters.

set -e

# Default values
DEFAULT_POOL_HOST="eu-de02.miningrigrentals.com"
DEFAULT_POOL_PORT="3333"
DEFAULT_LISTEN_PORT="3333"

# Ask for credentials and configuration
read -p "Enter the MiningRigRentals pool host [${DEFAULT_POOL_HOST}]: " POOL_HOST
POOL_HOST=${POOL_HOST:-$DEFAULT_POOL_HOST}

read -p "Enter the MiningRigRentals pool port [${DEFAULT_POOL_PORT}]: " POOL_PORT
POOL_PORT=${POOL_PORT:-$DEFAULT_POOL_PORT}

read -p "Enter the local listen port for your Bitaxe miner [${DEFAULT_LISTEN_PORT}]: " LISTEN_PORT
LISTEN_PORT=${LISTEN_PORT:-$DEFAULT_LISTEN_PORT}

read -p "Enter your MiningRigRentals username and worker (e.g. username.worker): " MRR_USER
read -s -p "Enter your MiningRigRentals password: " MRR_PASS
printf "\n"

# Determine script location
SCRIPT_DIR=$(dirname "$(realpath "$0")")
PY_SCRIPT_SOURCE="${SCRIPT_DIR}/stratum_minimal_proxy.py"
if [ ! -f "$PY_SCRIPT_SOURCE" ]; then
    echo "Error: stratum_minimal_proxy.py not found in $SCRIPT_DIR."
    exit 1
fi

# Copy the Python script to /usr/local/bin
TARGET_DIR="/usr/local/bin"
TARGET_SCRIPT="${TARGET_DIR}/stratum_minimal_proxy.py"

echo "Copying proxy script to ${TARGET_SCRIPT} (requires sudo)..."
sudo cp "$PY_SCRIPT_SOURCE" "$TARGET_SCRIPT"
sudo chmod +x "$TARGET_SCRIPT"

# Create systemd service unit file
SERVICE_NAME="bitaxe-mrr-proxy.service"
SERVICE_PATH="/etc/systemd/system/${SERVICE_NAME}"

echo "Creating systemd service at ${SERVICE_PATH} (requires sudo)..."

sudo bash -c "cat > ${SERVICE_PATH}" <<SERVICEEOF
[Unit]
Description=Bitaxe MRR Proxy
After=network.target

[Service]
User=${USER}
ExecStart=/usr/bin/python3 ${TARGET_SCRIPT} \\
  --listen-port ${LISTEN_PORT} \\
  --pool-host ${POOL_HOST} \\
  --pool-port ${POOL_PORT} \\
  --user ${MRR_USER} \\
  --passw ${MRR_PASS}
Restart=always

[Install]
WantedBy=multi-user.target
SERVICEEOF

# Reload systemd and enable the service
echo "Reloading systemd daemon and enabling service..."
sudo systemctl daemon-reload
sudo systemctl enable ${SERVICE_NAME}
sudo systemctl start ${SERVICE_NAME}

echo "\nInstallation complete."
echo "The proxy is now running and will start automatically on boot."
echo "Bitaxe miners can connect to this Raspberry Pi on port ${LISTEN_PORT}."

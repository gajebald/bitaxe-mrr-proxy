#!/bin/bash
# Setup script for the Bitaxe MRR Proxy
# This script installs the stratum_minimal_proxy.py script and sets up a systemd service.
# It prompts for MiningRigRentals pool configuration parameters.

set -e

# Color output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

echo -e "${GREEN}========================================${NC}"
echo -e "${GREEN}   Bitaxe MRR Proxy Setup Script${NC}"
echo -e "${GREEN}========================================${NC}"
echo ""

# Check for Python 3
if ! command -v python3 &> /dev/null; then
    echo -e "${RED}Error: Python 3 is not installed.${NC}"
    echo "Please install Python 3.8 or newer and try again."
    exit 1
fi

# Check Python version (minimum 3.8)
PYTHON_VERSION=$(python3 -c 'import sys; print(f"{sys.version_info.major}.{sys.version_info.minor}")')
PYTHON_MAJOR=$(echo "$PYTHON_VERSION" | cut -d. -f1)
PYTHON_MINOR=$(echo "$PYTHON_VERSION" | cut -d. -f2)
if [ "$PYTHON_MAJOR" -lt 3 ] || ([ "$PYTHON_MAJOR" -eq 3 ] && [ "$PYTHON_MINOR" -lt 8 ]); then
    echo -e "${RED}Error: Python 3.8 or newer is required (found Python ${PYTHON_VERSION}).${NC}"
    exit 1
fi
echo -e "${GREEN}✓${NC} Python ${PYTHON_VERSION} detected"

# Check for systemctl
if ! command -v systemctl &> /dev/null; then
    echo -e "${RED}Error: systemctl is not available.${NC}"
    echo "This script requires a systemd-based Linux distribution."
    exit 1
fi
echo -e "${GREEN}✓${NC} systemd detected"

# Check for sudo
if ! command -v sudo &> /dev/null; then
    echo -e "${RED}Error: sudo is not installed.${NC}"
    exit 1
fi

echo ""

# Default values
DEFAULT_POOL_HOST="eu-de02.miningrigrentals.com"
DEFAULT_POOL_PORT="3333"
DEFAULT_LISTEN_PORT="3333"

# Available MiningRigRentals servers for reference
echo -e "${YELLOW}Available MiningRigRentals servers:${NC}"
echo "  - eu-de02.miningrigrentals.com (Europe - Germany)"
echo "  - us-east01.miningrigrentals.com (US - East)"
echo "  - us-west01.miningrigrentals.com (US - West)"
echo ""

# Ask for configuration
read -p "Enter the MiningRigRentals pool host [${DEFAULT_POOL_HOST}]: " POOL_HOST
POOL_HOST=${POOL_HOST:-$DEFAULT_POOL_HOST}

read -p "Enter the MiningRigRentals pool port [${DEFAULT_POOL_PORT}]: " POOL_PORT
POOL_PORT=${POOL_PORT:-$DEFAULT_POOL_PORT}

# Validate port number
if ! [[ "$POOL_PORT" =~ ^[0-9]+$ ]] || [ "$POOL_PORT" -lt 1 ] || [ "$POOL_PORT" -gt 65535 ]; then
    echo -e "${RED}Error: Invalid pool port number.${NC}"
    exit 1
fi

read -p "Enter the local listen port for your Bitaxe miner [${DEFAULT_LISTEN_PORT}]: " LISTEN_PORT
LISTEN_PORT=${LISTEN_PORT:-$DEFAULT_LISTEN_PORT}

# Validate listen port number
if ! [[ "$LISTEN_PORT" =~ ^[0-9]+$ ]] || [ "$LISTEN_PORT" -lt 1 ] || [ "$LISTEN_PORT" -gt 65535 ]; then
    echo -e "${RED}Error: Invalid listen port number.${NC}"
    exit 1
fi

# Note about credentials
echo ""
echo -e "${YELLOW}Note:${NC} The proxy forwards all traffic transparently."
echo "Your Bitaxe miner should send credentials directly to MiningRigRentals."
echo "The following credentials are stored for reference but not actively used by the proxy."
echo ""

read -p "Enter your MiningRigRentals username and worker (e.g. username.worker): " MRR_USER
if [ -z "$MRR_USER" ]; then
    echo -e "${YELLOW}Warning: No username provided. Using placeholder 'user.worker'.${NC}"
    MRR_USER="user.worker"
fi

read -s -p "Enter your MiningRigRentals password [x]: " MRR_PASS
echo ""
MRR_PASS=${MRR_PASS:-x}

# Determine script location
SCRIPT_DIR=$(dirname "$(realpath "$0")")
PY_SCRIPT_SOURCE="${SCRIPT_DIR}/stratum_minimal_proxy.py"
if [ ! -f "$PY_SCRIPT_SOURCE" ]; then
    echo -e "${RED}Error: stratum_minimal_proxy.py not found in $SCRIPT_DIR.${NC}"
    exit 1
fi

echo ""
echo -e "${GREEN}Configuration summary:${NC}"
echo "  Pool host:    ${POOL_HOST}"
echo "  Pool port:    ${POOL_PORT}"
echo "  Listen port:  ${LISTEN_PORT}"
echo "  Username:     ${MRR_USER}"
echo ""

# Copy the Python script to /usr/local/bin
TARGET_DIR="/usr/local/bin"
TARGET_SCRIPT="${TARGET_DIR}/stratum_minimal_proxy.py"

echo "Copying proxy script to ${TARGET_SCRIPT}..."
if ! sudo cp "$PY_SCRIPT_SOURCE" "$TARGET_SCRIPT"; then
    echo -e "${RED}Error: Failed to copy script. Check sudo permissions.${NC}"
    exit 1
fi
sudo chmod +x "$TARGET_SCRIPT"
echo -e "${GREEN}✓${NC} Proxy script installed"

# Create systemd service unit file
SERVICE_NAME="bitaxe-mrr-proxy.service"
SERVICE_PATH="/etc/systemd/system/${SERVICE_NAME}"

echo "Creating systemd service at ${SERVICE_PATH}..."

sudo bash -c "cat > ${SERVICE_PATH}" <<SERVICEEOF
[Unit]
Description=Bitaxe MRR Proxy - Stratum V1 Mining Proxy
Documentation=https://github.com/gajebald/bitaxe-mrr-proxy
After=network-online.target
Wants=network-online.target

[Service]
Type=simple
User=${USER}
ExecStart=/usr/bin/python3 ${TARGET_SCRIPT} \\
  --listen-port ${LISTEN_PORT} \\
  --pool-host ${POOL_HOST} \\
  --pool-port ${POOL_PORT} \\
  --user ${MRR_USER} \\
  --passw ${MRR_PASS}
Restart=always
RestartSec=5
StandardOutput=journal
StandardError=journal

[Install]
WantedBy=multi-user.target
SERVICEEOF

echo -e "${GREEN}✓${NC} Systemd service created"

# Reload systemd and enable the service
echo "Configuring systemd service..."
sudo systemctl daemon-reload
sudo systemctl enable "${SERVICE_NAME}" > /dev/null 2>&1
echo -e "${GREEN}✓${NC} Service enabled for auto-start"

# Stop existing service if running
sudo systemctl stop "${SERVICE_NAME}" > /dev/null 2>&1 || true
sudo systemctl start "${SERVICE_NAME}"
echo -e "${GREEN}✓${NC} Service started"

# Wait briefly and check service status
sleep 2
if systemctl is-active --quiet "${SERVICE_NAME}"; then
    echo ""
    echo -e "${GREEN}========================================${NC}"
    echo -e "${GREEN}   Installation complete!${NC}"
    echo -e "${GREEN}========================================${NC}"
    echo ""
    echo "The proxy is now running and will start automatically on boot."
    echo ""
    echo -e "${YELLOW}Bitaxe Configuration:${NC}"
    echo "  Pool URL:  $(hostname -I | awk '{print $1}'):${LISTEN_PORT}"
    echo "  Username:  Your MRR username.worker"
    echo "  Password:  Your MRR password (usually 'x')"
    echo ""
    echo -e "${YELLOW}Useful commands:${NC}"
    echo "  sudo systemctl status ${SERVICE_NAME}   # Check status"
    echo "  sudo journalctl -u ${SERVICE_NAME} -f   # View logs"
    echo "  sudo systemctl restart ${SERVICE_NAME}  # Restart service"
    echo "  sudo systemctl stop ${SERVICE_NAME}     # Stop service"
else
    echo ""
    echo -e "${RED}Warning: Service may not have started correctly.${NC}"
    echo "Check status with: sudo systemctl status ${SERVICE_NAME}"
    echo "View logs with: sudo journalctl -u ${SERVICE_NAME}"
fi

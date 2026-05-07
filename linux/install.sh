#!/bin/bash

echo "========================================"
echo " ShadowGuard Installation - Linux"
echo "========================================"
echo ""

# Check root
if [[ $EUID -ne 0 ]]; then
   echo "[ERROR] This script must be run as root"
   exit 1
fi

INSTALL_DIR="/opt/shadowguard"
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

echo "[1/5] Creating installation directory..."
mkdir -p "$INSTALL_DIR"

echo "[2/5] Copying files..."
cp -r "$SCRIPT_DIR"/* "$INSTALL_DIR/"
chmod +x "$INSTALL_DIR/shadowguard.sh"

echo "[3/5] Creating symbolic link..."
ln -sf "$INSTALL_DIR/shadowguard.sh" /usr/local/bin/shadowguard

echo "[4/5] Creating systemd service..."
cat > /etc/systemd/system/shadowguard.service <<EOF
[Unit]
Description=ShadowGuard Security Monitor
After=network.target

[Service]
Type=forking
ExecStart=$INSTALL_DIR/shadowguard.sh start
ExecStop=$INSTALL_DIR/shadowguard.sh stop
Restart=on-failure
User=root

[Install]
WantedBy=multi-user.target
EOF

systemctl daemon-reload

echo "[5/5] Setting permissions..."
chown -R root:root "$INSTALL_DIR"
chmod 700 "$INSTALL_DIR"

echo ""
echo "========================================"
echo " Installation Complete!"
echo "========================================"
echo ""
echo "Run: shadowguard start"
echo "Or enable at boot: systemctl enable shadowguard"
echo ""

#!/bin/bash
set -e

echo "Configuring systemd-resolved for AdGuard Home..."

# Create the configuration directory and file
sudo mkdir -p /etc/systemd/resolved.conf.d
sudo tee /etc/systemd/resolved.conf.d/adguardhome.conf > /dev/null <<EOF
[Resolve]
DNS=127.0.0.1
DNSStubListener=no
EOF

echo "Created /etc/systemd/resolved.conf.d/adguardhome.conf"

# Replace resolv.conf
if [ -f /etc/resolv.conf ] && [ ! -L /etc/resolv.conf ]; then
    sudo mv /etc/resolv.conf /etc/resolv.conf.backup
    echo "Backed up /etc/resolv.conf to /etc/resolv.conf.backup"
fi

sudo ln -sf /run/systemd/resolve/resolv.conf /etc/resolv.conf
echo "Linked /etc/resolv.conf to /run/systemd/resolve/resolv.conf"

# Reload systemd-resolved
sudo systemctl reload-or-restart systemd-resolved
echo "Reloaded systemd-resolved"

echo "Done! Port 53 should now be available for AdGuard Home."

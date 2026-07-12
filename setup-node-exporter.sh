#!/usr/bin/env bash

set -euo pipefail

VERSION="1.11.1"
OS="linux"
ARCH="amd64"

ARCHIVE="node_exporter-${VERSION}.${OS}-${ARCH}.tar.gz"
DIR="node_exporter-${VERSION}.${OS}-${ARCH}"
URL="https://github.com/prometheus/node_exporter/releases/download/v${VERSION}/${ARCHIVE}"

echo "==> Installing Node Exporter v${VERSION}"

# Install required packages
apt update
apt install -y wget tar

# Create node_exporter user
if ! id node_exporter &>/dev/null; then
    useradd --no-create-home --shell /usr/sbin/nologin node_exporter
fi

# Download
cd /tmp
rm -rf "${DIR}" "${ARCHIVE}"

wget -O "${ARCHIVE}" "${URL}"

# Extract
tar -xzf "${ARCHIVE}"

# Install binary
install -m 755 "${DIR}/node_exporter" /usr/local/bin/node_exporter

# Cleanup
rm -rf "${DIR}" "${ARCHIVE}"

# Create systemd service
cat >/etc/systemd/system/node_exporter.service <<EOF
[Unit]
Description=Prometheus Node Exporter
Documentation=https://github.com/prometheus/node_exporter
After=network-online.target
Wants=network-online.target

[Service]
User=node_exporter
Group=node_exporter
Type=simple
ExecStart=/usr/local/bin/node_exporter

Restart=always
RestartSec=5

[Install]
WantedBy=multi-user.target
EOF

# Reload systemd
systemctl daemon-reload

# Enable service
systemctl enable --now node_exporter

echo
echo "========================================"
echo "Node Exporter installed successfully!"
echo "========================================"
echo
systemctl --no-pager --full status node_exporter
echo
echo "Metrics endpoint:"
echo "http://$(hostname -I | awk '{print $1}'):9100/metrics"


#!/usr/bin/env bash

# Copyright (c) 2021-2024 tteck
# Author: michaderbastler
# License: MIT

source <(curl -s https://raw.githubusercontent.com/community-scripts/ProxmoxVE/main/misc/install.func)

color
verb_ip6
catch_errors

msg_info "Installing Dependencies"
apt-get install -y -q \
  curl \
  ca-certificates \
  tar \
  libusb-1.0-0 >/dev/null 2>&1
msg_ok "Installed Dependencies"

msg_info "Fetching Latest Bitfocus Companion Release Info"
RELEASE_JSON=$(curl -fsSL "https://api.bitfocus.io/v1/product/companion/packages?limit=20")
RELEASE=$(echo "$RELEASE_JSON" | grep -o '"version":"[^"]*","target":"linux-tgz"' | head -1 | awk -F'"' '{print $4}')
ASSET_URL=$(echo "$RELEASE_JSON" | grep -o '"uri":"[^"]*linux-x64[^"]*"' | head -1 | awk -F'"' '{print $4}')

if [[ -z "$ASSET_URL" ]]; then
  msg_error "Could not locate a Linux x64 release from the Bitfocus API."
  exit 1
fi
msg_ok "Latest release: ${RELEASE}"

msg_info "Downloading Bitfocus Companion ${RELEASE}"
mkdir -p /opt/companion
curl -fsSL "$ASSET_URL" -o /tmp/companion.tar.gz
tar -xzf /tmp/companion.tar.gz -C /opt/companion --strip-components=1
rm -f /tmp/companion.tar.gz
msg_ok "Downloaded and extracted Bitfocus Companion ${RELEASE}"

msg_info "Installing udev rules"
if [[ -f /opt/companion/50-companion-headless.rules ]]; then
  cp /opt/companion/50-companion-headless.rules /etc/udev/rules.d/
fi
msg_ok "Installed udev rules"

msg_info "Creating companion system user"
useradd --system --no-create-home --shell /usr/sbin/nologin companion 2>/dev/null || true
mkdir -p /opt/companion-config
chown -R companion:companion /opt/companion-config
chown -R companion:companion /opt/companion
msg_ok "Created companion user"

msg_info "Creating systemd service"
cat <<EOF >/etc/systemd/system/companion.service
[Unit]
Description=Bitfocus Companion
After=network.target
Wants=network-online.target

[Service]
Type=simple
User=companion
ExecStart=/opt/companion/companion_headless.sh --config-dir /opt/companion-config
WorkingDirectory=/opt/companion
Restart=on-failure
RestartSec=5
StandardOutput=journal
StandardError=journal
SyslogIdentifier=companion
Environment=NODE_ENV=production

[Install]
WantedBy=multi-user.target
EOF
msg_ok "Created systemd service"

msg_info "Enabling and starting Companion service"
systemctl daemon-reload
systemctl enable --now companion >/dev/null 2>&1
msg_ok "Started Companion service"

echo "${RELEASE}" >/opt/companion-config/version.txt

msg_info "Setting up MOTD"
cat <<EOF >/etc/motd

  Bitfocus Companion ${RELEASE}
  ─────────────────────────────────────────
  Web UI:  http://$(hostname -I | awk '{print $1}'):8000
  Config:  /opt/companion-config
  Service: systemctl status companion

  Script by glabutis
  https://github.com/glabutis/companion-proxmox

EOF
msg_ok "MOTD configured"

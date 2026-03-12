#!/usr/bin/env bash
source <(curl -s https://raw.githubusercontent.com/community-scripts/ProxmoxVE/main/misc/build.func)
# Copyright (c) 2021-2024 tteck
# Author: michaderbastler
# License: MIT

function header_info {
  clear
  cat <<"EOF"
  ____                                      _
 / ___|___  _ __ ___  _ __   __ _ _ __ (_) ___  _ __
| |   / _ \| '_ ` _ \| '_ \ / _` | '_ \| |/ _ \| '_ \
| |__| (_) | | | | | | |_) | (_| | | | | | (_) | | | |
 \____\___/|_| |_| |_| .__/ \__,_|_| |_|_|\___/|_| |_|
                      |_|
EOF
}

header_info
echo -e "Loading..."

APP="Companion"
var_disk="8"
var_cpu="2"
var_ram="512"
var_os="debian"
var_version="12"
var_unprivileged="1"
var_nesting="1"
var_keyctl="1"

variables
color
catch_errors

function default_settings() {
  CT_TYPE="1"
  PW=""
  CT_ID=$NEXTID
  HN=$NSAPP
  DISK_SIZE="$var_disk"
  CORE_COUNT="$var_cpu"
  RAM_SIZE="$var_ram"
  BRG="vmbr0"
  NET="dhcp"
  GATE=""
  APT_CACHER=""
  APT_CACHER_IP=""
  DISABLEIP6="no"
  MTU=""
  SD=""
  NS=""
  MAC=""
  VLAN=""
  SSH="no"
  VERB="no"
  echo_default
}

function update_script() {
  header_info
  check_container_storage
  check_container_resources
  if [[ ! -d /opt/companion ]]; then
    msg_error "No ${APP} Installation Found!"
    exit
  fi

  CURRENT=""
  [[ -f /opt/companion-config/version.txt ]] && CURRENT=$(cat /opt/companion-config/version.txt)

  RELEASE_JSON=$(curl -fsSL "https://api.bitfocus.io/v1/product/companion/packages?limit=20")
  LATEST=$(echo "$RELEASE_JSON" | grep -o '"version":"[^"]*","target":"linux-tgz"' | head -1 | awk -F'"' '{print $4}')
  ASSET_URL=$(echo "$RELEASE_JSON" | grep -o '"uri":"[^"]*linux-x64[^"]*"' | head -1 | awk -F'"' '{print $4}')

  msg_info "Updating Bitfocus Companion to ${LATEST}"
  systemctl stop companion
  rm -rf /opt/companion
  mkdir -p /opt/companion
  curl -fsSL "$ASSET_URL" -o /tmp/companion.tar.gz
  tar -xzf /tmp/companion.tar.gz -C /opt/companion --strip-components=1
  rm -f /tmp/companion.tar.gz
  chown -R companion:companion /opt/companion
  systemctl start companion
  echo "${LATEST}" >/opt/companion-config/version.txt
  msg_ok "Updated Bitfocus Companion to ${LATEST}"
  exit
}

start
build_container
description

# build.func already created and started the container, and installed base packages.
# It looks for install scripts only in the community-scripts repo, so we run ours now.
msg_info "Installing Bitfocus Companion"
pct exec "$CTID" -- bash -c "$(curl -fsSL https://raw.githubusercontent.com/glabutis/companion-proxmox/main/install/companion-install.sh)"
msg_ok "Installed Bitfocus Companion"

IP=$(pct exec "$CTID" -- hostname -I | awk '{print $1}')

msg_ok "Completed Successfully!\n"
echo -e "${CREATING}${GN}${APP} setup has been successfully initialized!${CL}"
echo -e "${INFO}${YW} Access Bitfocus Companion Web UI at:${CL}"
echo -e "${TAB}${GATEWAY}${BGN}http://${IP}:8000${CL}"

#!/bin/bash

# Source keys and UUIDs
source /usr/local/etc/xray/keys

# Get server IP
SERVER_IP=$(curl -s ifconfig.me)

# Generate VLESS links
VLESS_LINK_ANTIZAPRET="vless://${UUID_ANTIZAPRET}@${SERVER_IP}:443?encryption=none&flow=xtls-rprx-vision&security=reality&sni=www.microsoft.com&fp=chrome&pbk=${PUBLIC_KEY}&sid=0123456789abcdef&type=tcp&headerType=none#$1-antizapret"
VLESS_LINK_GLOBAL="vless://${UUID_GLOBAL}@${SERVER_IP}:8443?encryption=none&flow=xtls-rprx-vision&security=reality&sni=www.microsoft.com&fp=chrome&pbk=${PUBLIC_KEY}&sid=0123456789abcdef&type=tcp&headerType=none#$1-global"

# Print VLESS links
echo "VLESS link for client $1 (AntiZapret):"
echo "$VLESS_LINK_ANTIZAPRET"
echo
echo "VLESS link for client $1 (Global):"
echo "$VLESS_LINK_GLOBAL"
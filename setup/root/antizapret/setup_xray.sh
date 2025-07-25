#!/bin/bash

# Install Xray if not installed
if ! command -v xray &> /dev/null
then
    echo "Xray not found, installing..."
    bash -c "$(curl -L https://github.com/XTLS/Xray-install/raw/main/install-release.sh)" @ install
fi

# Generate keys
KEYS=$(xray x25519)
PRIVATE_KEY=$(echo "$KEYS" | awk '/Private key/ {print $3}')
PUBLIC_KEY=$(echo "$KEYS" | awk '/Public key/ {print $3}')

# Create xray config directory and clients directory
mkdir -p /usr/local/etc/xray/clients

# Save keys
echo "PUBLIC_KEY=${PUBLIC_KEY}" > /usr/local/etc/xray/keys
echo "PRIVATE_KEY=${PRIVATE_KEY}" >> /usr/local/etc/xray/keys

# Create initial empty config from template
CONFIG=$(cat /root/antizapret/config.json.template)
CONFIG=${CONFIG//'__CLIENTS_ANTIZAPRET__'/[]}
CONFIG=${CONFIG//'__CLIENTS_GLOBAL__'/[]}
CONFIG=${CONFIG//'${PRIVATE_KEY}'/$PRIVATE_KEY}
echo "$CONFIG" > /usr/local/etc/xray/config.json

# Install Xray
bash -c "$(curl -L https://github.com/XTLS/Xray-install/raw/main/install-release.sh)" @ install

# Setup iptables rules for Antizapret VLESS
ipset create antizapret-vless hash:ip family inet timeout 86400 &>/dev/null || ipset flush antizapret-vless

# TCP rules
iptables -t nat -N VLESS_ANTIZAPRET_TCP &>/dev/null
iptables -t nat -F VLESS_ANTIZAPRET_TCP
iptables -t nat -A VLESS_ANTIZAPRET_TCP -p tcp -j REDIRECT --to-ports 443
iptables -t nat -A PREROUTING -p tcp -m set --match-set antizapret-vless dst -j VLESS_ANTIZAPRET_TCP

# UDP rules
iptables -t mangle -N VLESS_ANTIZAPRET_UDP &>/dev/null
iptables -t mangle -F VLESS_ANTIZAPRET_UDP
iptables -t mangle -A VLESS_ANTIZAPRET_UDP -p udp -m set --match-set antizapret-vless dst -j TPROXY --on-port 1080 --tproxy-mark 1
iptables -t mangle -A PREROUTING -p udp -m set --match-set antizapret-vless dst -j VLESS_ANTIZAPRET_UDP

ip rule add fwmark 1 table 100 || true
ip route add local 0.0.0.0/0 dev lo table 100 || true

# Start and enable Xray service
systemctl start xray
systemctl enable xray
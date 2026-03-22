#!/usr/bin/env bash
set -euo pipefail

# =============================================================================
# WireGuard Key Generator
# Generates server + peer key pairs and preshared keys
# =============================================================================

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_DIR="$(dirname "$SCRIPT_DIR")"
KEYS_DIR="$PROJECT_DIR/keys"

# Load .env if present
if [[ -f "$PROJECT_DIR/.env" ]]; then
  set -a; source "$PROJECT_DIR/.env"; set +a
fi

PEER_COUNT="${1:-${PEER_COUNT:-6}}"

if ! command -v wg &> /dev/null; then
  echo "Error: WireGuard tools not found."
  echo "  macOS:   brew install wireguard-tools"
  echo "  Ubuntu:  sudo apt install wireguard-tools"
  exit 1
fi

if [[ -d "$KEYS_DIR" && -f "$KEYS_DIR/server.key" ]]; then
  echo "Keys already exist in $KEYS_DIR. Delete the directory to regenerate."
  exit 0
fi

mkdir -p "$KEYS_DIR"

echo "==> Generating server key pair..."
wg genkey | tee "$KEYS_DIR/server.key" | wg pubkey > "$KEYS_DIR/server.pub"

echo "==> Generating $PEER_COUNT peer key pairs + preshared keys..."
for i in $(seq 1 "$PEER_COUNT"); do
  wg genkey | tee "$KEYS_DIR/peer${i}.key" | wg pubkey > "$KEYS_DIR/peer${i}.pub"
  wg genpsk > "$KEYS_DIR/peer${i}.psk"
  echo "  peer${i}: done"
done

chmod 600 "$KEYS_DIR"/*.key "$KEYS_DIR"/*.psk

echo ""
echo "Keys generated in $KEYS_DIR/"
echo ""
echo "Server public key: $(cat "$KEYS_DIR/server.pub")"
echo ""
for i in $(seq 1 "$PEER_COUNT"); do
  echo "Peer ${i} public key: $(cat "$KEYS_DIR/peer${i}.pub")"
done
echo ""
echo "Next: run ./scripts/generate-china-routes.py then cd infra && ./deploy.sh"

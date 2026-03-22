#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_DIR="$(dirname "$SCRIPT_DIR")"

# Load .env if present
if [[ -f "$PROJECT_DIR/.env" ]]; then
  set -a; source "$PROJECT_DIR/.env"; set +a
fi

RG="${RESOURCE_GROUP:-rg-vpn-personal}"
VM="${VM_NAME:-vm-wireguard}"

echo "Starting VM $VM..."
az vm start --resource-group "$RG" --name "$VM"

PUBLIC_IP=$(az network public-ip show \
  --resource-group "$RG" \
  --name "pip-wireguard" \
  --query ipAddress \
  --output tsv)

echo ""
echo "VM is running."
echo "Public IP: $PUBLIC_IP"
echo "WireGuard endpoint: $PUBLIC_IP:${WG_PORT:-443}"
echo ""
echo "Connect your WireGuard client now."

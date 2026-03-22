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

echo "Deallocating VM $VM (stops billing)..."
az vm deallocate --resource-group "$RG" --name "$VM"

echo "VM deallocated. No compute charges while stopped."

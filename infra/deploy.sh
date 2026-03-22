#!/usr/bin/env bash
set -euo pipefail

# =============================================================================
# Azure WireGuard VPN Deployment Script
# Deploys a B1s VM with WireGuard pre-configured via cloud-init
# =============================================================================

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_DIR="$(dirname "$SCRIPT_DIR")"
KEYS_DIR="$PROJECT_DIR/keys"
CLOUD_INIT_TEMPLATE="$SCRIPT_DIR/cloud-init.yaml"

# Load .env if present
if [[ -f "$PROJECT_DIR/.env" ]]; then
  set -a; source "$PROJECT_DIR/.env"; set +a
fi

RESOURCE_GROUP="${RESOURCE_GROUP:-rg-vpn-personal}"
LOCATION="${LOCATION:-southeastasia}"
VM_SIZE="${VM_SIZE:-Standard_B2s}"
DEPLOYMENT_NAME="vpn-deploy-$(date +%Y%m%d-%H%M%S)"
PEER_COUNT="${PEER_COUNT:-6}"

# --- Pre-flight checks ---
echo "==> Pre-flight checks..."

if ! command -v az &> /dev/null; then
  echo "Error: Azure CLI not found. Install from https://learn.microsoft.com/en-us/cli/azure/install-azure-cli"
  exit 1
fi

if ! az account show &> /dev/null; then
  echo "Error: Not logged in. Run 'az login' first."
  exit 1
fi

if [[ ! -f "$KEYS_DIR/server.key" ]]; then
  echo "Error: WireGuard keys not found. Run './scripts/generate-keys.sh' first."
  exit 1
fi

# Check for SSH public key
SSH_KEY_FILE="${SSH_KEY_FILE:-$HOME/.ssh/id_rsa.pub}"
if [[ ! -f "$SSH_KEY_FILE" ]]; then
  # Try ed25519
  SSH_KEY_FILE="$HOME/.ssh/id_ed25519.pub"
fi
if [[ ! -f "$SSH_KEY_FILE" ]]; then
  echo "Error: SSH public key not found at ~/.ssh/id_rsa.pub or ~/.ssh/id_ed25519.pub"
  echo "  Generate one: ssh-keygen -t ed25519"
  echo "  Or set SSH_KEY_FILE=/path/to/key.pub"
  exit 1
fi

SSH_PUBLIC_KEY=$(cat "$SSH_KEY_FILE")
echo "  Subscription: $(az account show --query name -o tsv)"
echo "  Resource Group: $RESOURCE_GROUP"
echo "  Location: $LOCATION"
echo "  SSH Key: $SSH_KEY_FILE"
echo ""

# --- Template cloud-init with actual keys ---
echo "==> Preparing cloud-init configuration..."

CLOUD_INIT_RENDERED=$(cat "$CLOUD_INIT_TEMPLATE")

# Inject server private key
SERVER_KEY=$(cat "$KEYS_DIR/server.key")
CLOUD_INIT_RENDERED="${CLOUD_INIT_RENDERED//\{\{SERVER_PRIVATE_KEY\}\}/$SERVER_KEY}"

# Inject peer public keys and preshared keys
for i in $(seq 1 "$PEER_COUNT"); do
  PEER_PUB=$(cat "$KEYS_DIR/peer${i}.pub")
  PEER_PSK=$(cat "$KEYS_DIR/peer${i}.psk")
  CLOUD_INIT_RENDERED="${CLOUD_INIT_RENDERED//\{\{PEER${i}_PUBLIC_KEY\}\}/$PEER_PUB}"
  CLOUD_INIT_RENDERED="${CLOUD_INIT_RENDERED//\{\{PEER${i}_PSK\}\}/$PEER_PSK}"
done

# Base64 encode for Bicep customData
CLOUD_INIT_B64=$(echo "$CLOUD_INIT_RENDERED" | base64)

echo "  Cloud-init prepared with server + $PEER_COUNT peer keys."

# --- Create Resource Group ---
echo "==> Creating resource group '$RESOURCE_GROUP' in '$LOCATION'..."
az group create --name "$RESOURCE_GROUP" --location "$LOCATION" --output none

# --- Validate Bicep ---
echo "==> Validating Bicep templates..."
az deployment group validate \
  --resource-group "$RESOURCE_GROUP" \
  --template-file main.bicep \
  --parameters main.bicepparam \
  --parameters sshPublicKey="$SSH_PUBLIC_KEY" \
  --parameters vmSize="$VM_SIZE" \
  --parameters cloudInitData="$CLOUD_INIT_B64" \
  --output none

echo "  Validation passed."

# --- Confirm ---
echo ""
echo "==> Ready to deploy WireGuard VM ($VM_SIZE + static IP)."
echo "  VM provisioning takes ~2-3 minutes."
read -p "  Continue? [y/N] " confirm
if [[ ! "$confirm" =~ ^[Yy]$ ]]; then
  echo "Aborted."
  exit 0
fi

# --- Deploy ---
echo ""
echo "==> Deploying infrastructure..."

az deployment group create \
  --resource-group "$RESOURCE_GROUP" \
  --name "$DEPLOYMENT_NAME" \
  --template-file main.bicep \
  --parameters main.bicepparam \
  --parameters sshPublicKey="$SSH_PUBLIC_KEY" \
  --parameters vmSize="$VM_SIZE" \
  --parameters cloudInitData="$CLOUD_INIT_B64" \
  --output table

echo ""
echo "==> Deployment complete!"

# --- Show Public IP ---
echo ""
echo "==> WireGuard VM Public IP:"
PUBLIC_IP=$(az network public-ip show \
  --resource-group "$RESOURCE_GROUP" \
  --name "pip-wireguard" \
  --query ipAddress \
  --output tsv)
echo "  $PUBLIC_IP"

echo ""
echo "==> Next steps:"
echo "  1. Wait ~1-2 minutes for cloud-init to finish WireGuard setup"
echo "  2. Run: python3 scripts/generate-china-routes.py"
echo "  3. Run: ./scripts/generate-client-configs.sh"
echo "  4. Import configs/peer*.conf into WireGuard apps on your devices"
echo ""
echo "  SSH into VM:  ssh azureuser@$PUBLIC_IP"
echo "  Check WireGuard: ssh azureuser@$PUBLIC_IP 'sudo wg show'"
echo ""
echo "  Start/stop VM to save costs:"
echo "    ./scripts/vm-start.sh"
echo "    ./scripts/vm-stop.sh"

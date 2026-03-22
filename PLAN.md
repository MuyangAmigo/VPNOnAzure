# VPN on Azure — Implementation Plan

## Context

Personal VPN for accessing geo-restricted services. WireGuard + Xray VLESS+Reality on an Azure VM. Configurable region and peer count.

## Cost Estimate

| Component | Approximate Monthly Cost |
|-----------|-------------------------|
| Standard_B1s VM | ~$8 |
| Standard_B2s VM | ~$30 |
| Static Public IP | ~$4 |
| Managed Disk (30 GB) | ~$1 |

Deallocate the VM when not in use (`./scripts/vm-stop.sh`) to save on compute costs.

## Network Design

- **VNet:** `10.100.0.0/16`
- **VM Subnet:** `10.100.1.0/24`
- **WireGuard Tunnel:** `10.0.0.0/24` (server: `.1`, peers: `.2`-`.N`)
- **Ports:** UDP 443 (WireGuard), TCP 443 (Xray VLESS+Reality), TCP 22 (SSH)

## Deployment Steps

1. `cp .env.example .env` — Configure your settings
2. `./scripts/generate-keys.sh` — Generate WireGuard key pairs
3. `az login` — Authenticate to Azure
4. `cd infra && ./deploy.sh` — Deploy VM (~2-3 min), cloud-init installs WireGuard
5. `./scripts/generate-client-configs.sh` — Generate WireGuard .conf files
6. (Optional) SSH to VM and install Xray VLESS+Reality
7. Import configs on devices (WireGuard app or Shadowrocket)

## Verification

1. SSH to VM: `ssh azureuser@<ip>` then `sudo wg show` — confirm WireGuard running
2. Connect client, visit ifconfig.me — should show Azure VM IP
3. Test connectivity to geo-restricted services

## Security

- SSH key-only authentication (no passwords)
- WireGuard public-key auth with preshared keys
- Xray VLESS+Reality (traffic disguised as TLS 1.3)
- NSG restricts inbound to UDP 443 + TCP 443 + SSH 22
- All private keys gitignored

## Known Limitations

- GFW may throttle WireGuard protocol even on port 443. Xray VLESS+Reality via Shadowrocket provides better throughput.
- iOS WireGuard app cannot handle >100 AllowedIPs routes. Full tunnel only.

## TODO

- [ ] Automate Xray installation in cloud-init.yaml
- [ ] Server-side split tunneling (ipset + policy routing)
- [ ] Add NSG rule for TCP 443 (Xray VLESS+Reality)

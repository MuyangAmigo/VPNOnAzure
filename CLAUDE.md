# VPNOnAzure

Personal VPN on Azure using WireGuard + Xray VLESS+Reality, deployed via Azure Bicep.

## Architecture

- **Protocols:** WireGuard (UDP 443) + Xray VLESS+Reality (TCP 443)
- **Server:** Azure VM (Ubuntu 24.04), configurable size and region
- **IaC:** Azure Bicep
- **Network:** VNet `10.100.0.0/16`, VM subnet `10.100.1.0/24`, WireGuard tunnel `10.0.0.0/24`
- **Routing:** Full tunnel (`0.0.0.0/0`) — all traffic through VPN
- **Clients:** Configurable number of WireGuard peers (macOS, iOS, Windows) + Xray-compatible clients via VLESS

## Project Structure

```
.env.example        Configuration template (copy to .env)
infra/              Bicep templates and deployment
  main.bicep        Orchestrator module
  main.bicepparam   Parameters (overridden by deploy.sh from .env)
  cloud-init.yaml   WireGuard server bootstrap template
  modules/          vnet.bicep, publicip.bicep, nsg.bicep, vm.bicep
  deploy.sh         One-command deploy (templates cloud-init, deploys VM)
scripts/            Operational scripts
  generate-keys.sh            WireGuard key generation (server + N peers)
  generate-china-routes.py    Fetch APNIC data, compute AllowedIPs exclusion
  generate-client-configs.sh  Produce .conf files for each peer
  vm-start.sh / vm-stop.sh   Start/stop VM to save costs
clients/            Per-platform setup guides
configs/            Generated .conf configs (gitignored)
keys/               WireGuard keys (gitignored)
```

## Commands

- Configure: `cp .env.example .env` then edit `.env`
- Generate keys: `./scripts/generate-keys.sh`
- Deploy infra: `cd infra && ./deploy.sh`
- Generate client configs: `./scripts/generate-client-configs.sh`
- Start VM: `./scripts/vm-start.sh`
- Stop VM: `./scripts/vm-stop.sh`

## Conventions

- All scripts read configuration from `.env` (with sensible defaults)
- Bicep modules are in `infra/modules/`, orchestrated by `infra/main.bicep`
- Private keys (`keys/`) and client configs (`configs/`) are gitignored — never commit them
- Cloud-init template uses `{{PLACEHOLDER}}` syntax, substituted by deploy.sh
- WireGuard uses UDP port 443 by default (configurable via WG_PORT in .env)
- Xray VLESS+Reality runs on TCP 443 alongside WireGuard (installed manually post-deploy)
- WireGuard tunnel IPs: server `10.0.0.1`, peers `10.0.0.2` through `10.0.0.N`

## Notes

- Client-side split tunneling (AllowedIPs exclusion) doesn't work well on iOS — route count limit causes connectivity failure. Use `0.0.0.0/0` full tunnel instead.
- Xray VLESS+Reality is not yet automated in cloud-init — installed manually via SSH after deploy.
- `generate-china-routes.py` computes country-level IP exclusions from APNIC data for split tunneling.

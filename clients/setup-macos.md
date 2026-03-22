# macOS WireGuard Setup

## Install WireGuard

Download **WireGuard** from the [Mac App Store](https://apps.apple.com/us/app/wireguard/id1451685025).

## Import Configuration

1. Open WireGuard
2. Click **Import Tunnel(s) from File...** (or ⌘I)
3. Select your assigned `configs/peerN.conf` file
4. Click **Activate** to connect

## Verify

```bash
# Should return the Azure VM's public IP
curl ifconfig.me

# Chinese sites should still work (bypassing VPN)
curl -I https://www.bilibili.com
```

## Start/Stop VPN

- Toggle the tunnel on/off in the WireGuard app or menu bar icon.
- If the VM is stopped, start it first: `./scripts/vm-start.sh`

## Notes

- By default, the config uses full tunnel (`0.0.0.0/0`) — all traffic goes through VPN.
- If `generate-china-routes.py` was run before generating configs, split tunneling is used instead.
- `PersistentKeepalive = 25` keeps the connection alive behind NAT.
- DNS is set to Cloudflare (1.1.1.1) and Google (8.8.8.8) by default (configurable in `.env`).

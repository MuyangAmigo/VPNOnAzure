# Windows WireGuard Setup

## Install WireGuard

Download from [wireguard.com/install](https://www.wireguard.com/install/) and run the installer.

## Import Configuration

1. Open WireGuard
2. Click **Import tunnel(s) from file**
3. Select your assigned `configs\peerN.conf` file
4. Click **Activate** to connect

## Verify

```powershell
# Should return the Azure VM's public IP
Invoke-RestMethod ifconfig.me

# Test that Chinese sites still work
Invoke-RestMethod -Uri https://www.bilibili.com -Method Head
```

## Start/Stop VPN

- Toggle the tunnel on/off in the WireGuard app.
- If the VM is stopped, start it from Azure CLI or portal first.

## Notes

- By default, the config uses full tunnel (`0.0.0.0/0`) — all traffic goes through VPN.
- If `generate-china-routes.py` was run before generating configs, split tunneling is used instead.
- DNS is set to Cloudflare (1.1.1.1) and Google (8.8.8.8) by default (configurable in `.env`).
- PersistentKeepalive keeps the tunnel alive behind NAT.

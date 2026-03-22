# iOS WireGuard Setup

## Install WireGuard

Download **WireGuard** from the [App Store](https://apps.apple.com/us/app/wireguard/id1441195209).

## Import Configuration

**Option A — QR Code (recommended):**
1. Open WireGuard on your iPhone/iPad
2. Tap **+** → **Create from QR code**
3. On your Mac/PC, display the QR code: `cat configs/peerN.qr.txt`
4. Scan the QR code and name the tunnel

**Option B — File transfer:**
1. AirDrop or email the `configs/peerN.conf` file to your device
2. Open the file → it opens in WireGuard automatically
3. Tap **Allow** to add the VPN configuration

## Connect

1. Toggle the tunnel **on** in the WireGuard app
2. Or use Settings → VPN to toggle

## Verify

- Visit [ifconfig.me](https://ifconfig.me) in Safari — should show Azure IP
- Open Bilibili or other Chinese apps — should work normally (bypasses VPN)

## Notes

- Install `qrencode` on your Mac for QR codes: `brew install qrencode`
- Then regenerate: `./scripts/generate-client-configs.sh`
- The VPN auto-reconnects when the VM is running (PersistentKeepalive).

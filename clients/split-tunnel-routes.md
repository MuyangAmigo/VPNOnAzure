# Split Tunnel: China IP Exclusion

## How It Works

Instead of maintaining a list of individual services, we exclude **all China IP ranges** from the VPN tunnel:

- **Through VPN:** All non-China traffic (Netflix, YouTube, Google, etc.) → routed to Azure US
- **Direct (bypass VPN):** All China traffic (Bilibili, iQiyi, WeChat, Baidu, Taobao, etc.) → local internet

This works because Chinese services are hosted on China-allocated IP addresses.

## Implementation

WireGuard's `AllowedIPs` field controls which traffic enters the tunnel. We set it to **everything except China IPs and private ranges**.

The `scripts/generate-china-routes.py` script:
1. Fetches APNIC delegation data (authoritative source for IP allocations by country)
2. Extracts all China (CN) IPv4 allocations (~8000 entries)
3. Also excludes private ranges (10.0.0.0/8, 172.16.0.0/12, 192.168.0.0/16) so LAN access works
4. Computes the complement and aggregates into ~150-200 CIDR entries
5. Writes the result to `configs/china-exclude-allowedips.txt`

This is then injected into each client `.conf` file as the `AllowedIPs` value.

## Updating Routes

APNIC data updates periodically. To refresh:

```bash
python3 scripts/generate-china-routes.py
./scripts/generate-client-configs.sh
```

Then re-import the updated `.conf` files on your devices.

## Services Automatically Excluded

Any service hosted on China IP ranges, including:
- **Video:** Bilibili, iQiyi, Youku, Tencent Video, Mango TV, Douyin
- **Music:** NetEase Cloud Music, QQ Music, Kugou, Kuwo
- **Social:** WeChat, Weibo, Xiaohongshu, Zhihu, Douban
- **Shopping:** Taobao, JD, Pinduoduo
- **Utilities:** Baidu, Alipay, Amap/Gaode, Didi

## Limitations

- Services using CDN nodes outside China may route through VPN
- If a Chinese service uses overseas servers, that traffic goes through VPN (usually fine)
- Newly allocated IP blocks may take a refresh cycle to appear in APNIC data

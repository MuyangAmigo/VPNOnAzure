#!/usr/bin/env python3
"""
Fetch APNIC delegation data and compute WireGuard AllowedIPs that exclude China IP ranges.

This routes all traffic through VPN EXCEPT:
  - China (CN) IPv4 allocations (from APNIC)
  - Private/reserved ranges (LAN access preserved)
  - Loopback

Output: configs/china-exclude-allowedips.txt
"""

import ipaddress
import math
import os
import sys
import urllib.request

APNIC_URL = "https://ftp.apnic.net/stats/apnic/delegated-apnic-latest"

SCRIPT_DIR = os.path.dirname(os.path.abspath(__file__))
PROJECT_DIR = os.path.dirname(SCRIPT_DIR)
OUTPUT_FILE = os.path.join(PROJECT_DIR, "configs", "china-exclude-allowedips.txt")

# Ranges to exclude from VPN (go direct, not through tunnel)
EXCLUDE_EXTRA = [
    # Private networks (LAN access)
    ipaddress.IPv4Network("10.0.0.0/8"),
    ipaddress.IPv4Network("172.16.0.0/12"),
    ipaddress.IPv4Network("192.168.0.0/16"),
    # Loopback
    ipaddress.IPv4Network("127.0.0.0/8"),
    # Link-local
    ipaddress.IPv4Network("169.254.0.0/16"),
    # Multicast & reserved
    ipaddress.IPv4Network("224.0.0.0/3"),
]


def fetch_china_networks():
    """Fetch APNIC data and extract China IPv4 allocations."""
    print(f"Fetching APNIC delegation data from {APNIC_URL}...")
    req = urllib.request.Request(APNIC_URL, headers={"User-Agent": "wireguard-china-routes/1.0"})
    with urllib.request.urlopen(req, timeout=30) as resp:
        data = resp.read().decode("utf-8")

    networks = []
    for line in data.splitlines():
        parts = line.split("|")
        if len(parts) >= 5 and parts[1] == "CN" and parts[2] == "ipv4":
            start_ip = parts[3]
            host_count = int(parts[4])
            prefix_len = 32 - int(math.log2(host_count))
            networks.append(ipaddress.IPv4Network(f"{start_ip}/{prefix_len}"))

    print(f"  Found {len(networks)} China IPv4 allocations")
    return networks


def compute_allowed_ips(exclude_networks):
    """Compute the complement: 0.0.0.0/0 minus all excluded networks.

    Uses a sorted, sequential approach for efficiency.
    """
    # Pre-aggregate exclusions to minimize fragmentation
    exclude_sorted = list(ipaddress.collapse_addresses(exclude_networks))
    print(f"  Aggregated exclusions to {len(exclude_sorted)} networks")

    allowed = {ipaddress.IPv4Network("0.0.0.0/0")}

    for exclude_net in exclude_sorted:
        new_allowed = set()
        for net in allowed:
            if net.overlaps(exclude_net):
                try:
                    new_allowed.update(net.address_exclude(exclude_net))
                except ValueError:
                    pass
            else:
                new_allowed.add(net)
        allowed = new_allowed

    return sorted(allowed, key=lambda n: (n.network_address, n.prefixlen))


def reduce_routes(networks, max_routes=1500):
    """Reduce route count to stay within client limits.

    Progressively lowers the max prefix length until route count is acceptable.
    Routes more specific than the cutoff are dropped — this means some small
    China allocations get routed through VPN, which is an acceptable trade-off.
    """
    for max_prefix in range(24, 7, -1):
        reduced = list(ipaddress.collapse_addresses(
            net for net in networks if net.prefixlen <= max_prefix
        ))
        if len(reduced) <= max_routes:
            print(f"  Using max prefix /{max_prefix} -> {len(reduced)} routes")
            return reduced
    return list(ipaddress.collapse_addresses(networks))


def main():
    china_nets = fetch_china_networks()

    all_exclude = china_nets + EXCLUDE_EXTRA
    print(f"  Total exclusions: {len(all_exclude)} networks")

    print("Computing allowed IPs (complement of excluded ranges)...")
    allowed = compute_allowed_ips(all_exclude)
    print(f"  Exact complement: {len(allowed)} routes")

    # Reduce route count for client compatibility (iOS/Android limits)
    # Drop routes more specific than /24 — minor over-routing is acceptable
    print("Reducing route count (dropping routes more specific than /24)...")
    allowed = reduce_routes(allowed)

    os.makedirs(os.path.dirname(OUTPUT_FILE), exist_ok=True)

    # Write as comma-separated AllowedIPs value
    allowed_str = ", ".join(str(net) for net in allowed)
    with open(OUTPUT_FILE, "w") as f:
        f.write(allowed_str)

    print(f"  {len(allowed)} routes written to {OUTPUT_FILE}")
    print("Done.")


if __name__ == "__main__":
    main()

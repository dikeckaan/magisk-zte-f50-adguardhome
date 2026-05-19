# adguardhome

Network-wide DNS ad-blocker for rooted Android (ZTE F50) — wraps the
[AdGuard Home](https://github.com/AdguardTeam/AdGuardHome) daemon as a Magisk
module so the device transparently filters DNS queries for every hotspot
client.

## How it works

The Android base image already runs `dnsmasq` on port 53 to serve DHCP +
DNS for the hotspot subnet. We don't disturb that — AdGuard Home runs in
parallel on port **5353**, and an iptables NAT rule on `br0` (the hotspot
bridge) transparently redirects all traffic destined to `br0:53` to
`127.0.0.1:5353`:

```
[ phone over WiFi ] --DNS:53--> br0 --[iptables NAT]--> AGH:5353
                                                          |
                                                          v
                                       DoH upstream (Cloudflare/Google)
```

The device itself (statusbot, system services, etc.) keeps using the normal
Android resolver — only hotspot clients get filtered. If you want the device
itself filtered too, point its DNS at `127.0.0.1:5353` manually.

## What's filtered

The seed config enables two blocklists, both maintained by AdGuard:

1. **AdGuard DNS filter** — general-purpose ad/tracker blocklist
2. **AdAway Default Blocklist** — community-maintained Android-focused list

You can add more lists, set custom rules, or tweak per-client filtering
from the web UI.

## Web UI

After flashing and rebooting, connect any phone/laptop to the hotspot and
open:

```
http://192.168.0.1:3000
```

The first-run wizard asks you to:
1. Pick an admin username + password (saved hashed in
   `/data/adguardhome/AdGuardHome.yaml`)
2. Confirm the listen ports (already set: 3000 for web, 5353 for DNS)
3. Done.

Once the wizard finishes the daemon restarts itself and starts serving
filtered DNS. The supervisor in `service.sh` will keep it running across
crashes.

## Resource cost

| Resource | Cost |
|---|---|
| Disk | 31 MB binary + ~5 MB config/logs |
| RAM | ~50-80 MB (Go runtime + cache) |
| CPU | Negligible at idle; bursts during query log writes |

On 2 GB devices that's ~3% of RAM — acceptable for a router-like deployment.
Disable via the statusbot `/adguard off` command if you want to free it
temporarily.

## Requirements

- Magisk 20.4+
- Android arm64 (the bundled binary is `AdGuardHome_linux_arm64`)
- `iptables` (present on stock Android)
- Hotspot bridge must be named `br0` (default on ZTE F50; tweak `service.sh`
  if your kernel uses a different name)

## Installation

```
# Local zip flash via Magisk Manager, or:
adb push adguardhome-v1.0.0.zip /sdcard/
magisk --install-module /sdcard/adguardhome-v1.0.0.zip
reboot
```

After the device comes back up:
1. Wait ~25 s for the daemon's warm-up sleep to finish.
2. Connect a client to the hotspot.
3. Open `http://192.168.0.1:3000` and finish the wizard.

## Bot integration

[statusbot](https://github.com/dikeckaan/magisk-zte-f50-statusbot) v2.12+
adds an `/adguard` command:

```
/adguard status       → daemon up? RAM? today's blocked count
/adguard on           → start daemon
/adguard off          → stop daemon (free RAM)
/adguard stats        → top 5 blocked domains + total queries today
/adguard log          → last 10 query log entries
```

## Verifying it's working

From a hotspot client:

```
nslookup ads.example.com 192.168.0.1
# Should return 0.0.0.0 (blocked) for any domain in the blocklist
```

Or visit `http://192.168.0.1:3000/#/query_log` in the web UI — you'll see
queries streaming in real time, labeled `Blocked` or `OK`.

## Uninstall

Removing the module via Magisk Manager runs `uninstall.sh`, which:
- Kills the daemon and its supervisor
- Removes both iptables NAT redirect rules
- Keeps `/data/adguardhome/` (config, query log, stats) so reinstalling
  preserves your setup. Wipe manually with `rm -rf /data/adguardhome` if
  you want a clean slate.

## Updating

The module declares an `updateJson` URL, so the statusbot `/update` command
auto-detects new releases and reinstalls without a manual flash. Releases
are cut by GitHub Actions whenever `module.prop` is bumped.

## License

The wrapper module is GPL-3.0. AdGuard Home itself is also GPL-3.0
(© AdGuard Software Ltd.).

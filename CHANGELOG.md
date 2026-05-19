# Changelog

## v1.0.1 — 2026-05-19
- **Fixed**: `statistics.interval: 24` in the seed YAML had no unit, which
  AdGuard Home schema 34 rejects (`time: missing unit in duration "24"`).
  Changed to `24h`. Affected fresh installs only.
- **Fixed**: AdGuard's Go binary uses its own CA pool, not Android's, so
  DoH upstreams and blocklist downloads failed with "x509: certificate
  signed by unknown authority". `service.sh` now exports
  `SSL_CERT_FILE` pointing at `bin-utils`'s `cacert.pem` (or
  `/system/etc/cacert.pem` as a fallback).
- No code changes to the binary itself.

## v1.0.0 — 2026-05-19
- Initial release.
- AdGuard Home v0.107.74 static arm64 binary bundled.
- DNS on UDP/TCP 5353, web UI on TCP 3000.
- Transparent iptables NAT redirect on `br0` so hotspot clients are
  filtered automatically (host device itself is untouched).
- Seed config with two upstream DoH resolvers (Cloudflare + Google) and
  two blocklists (AdGuard DNS filter + AdAway Default Blocklist).
- Supervised daemon with auto-restart and log rotation.
- Self-update via the statusbot `/update` command.

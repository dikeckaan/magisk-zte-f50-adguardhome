# Changelog

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

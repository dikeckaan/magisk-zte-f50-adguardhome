# Changelog

## v1.0.3 — 2026-05-19
- **Service migration to `bin-utils/lib/common.sh`** (now a hard dep,
  v1.3.0+ required). `service.sh` dropped its inline `wait_for_bridge`,
  `find_ca_bundle`, log-rotate and `ensure_redirect` definitions — they
  all live in the shared library now. Net: 87 → 58 lines.
- `customize.sh` now hard-requires bin-utils v1.3.0+ at install time.
- Behaviour unchanged: same iptables policy (insert at PREROUTING pos 1,
  re-assert every 5 min), same SSL_CERT_FILE export, same supervisor.

## v1.0.2 — 2026-05-19
- **Fixed**: ZTE firmware adds its own DNAT-to-1.1.1.1 rule on every
  boot at the top of nat PREROUTING. The previous `-A` (append) put our
  REDIRECT below it, so hotspot client DNS queries were forwarded to
  Cloudflare directly and never reached AdGuard Home — querylog stayed
  empty. We now use `-I PREROUTING 1` so our rule always sits at
  position 1 and matches first.
- **Robustness**: `service.sh` waits up to 90 s for `br0` to come up
  before adding rules. A keepalive loop re-asserts the redirect every
  5 min, so any future PREROUTING reordering by the firmware or by
  `netd` is healed automatically.
- **Cleaner uninstall**: removes every copy of our redirect (the
  keepalive may have inserted several across boots) and does NOT touch
  ZTE's vendor DNAT rules.
- No binary changes.

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

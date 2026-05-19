#!/system/bin/sh
# AdGuard Home daemon supervisor.
#
# - Launches AdGuardHome with working dir /data/adguardhome
# - Hijacks hotspot DNS by inserting an iptables REDIRECT at the top of
#   nat PREROUTING. ZTE firmware adds its own DNAT-to-1.1.1.1 rule on
#   boot; we don't delete it (preserves vendor behaviour for tun0 / VPN
#   paths) but our rule is inserted before it so br0 traffic matches
#   first. iptables uses first-match, so this is a clean override.
# - Auto-restarts on crash. Log at /data/adguardhome/daemon.log.

DATA=/data/adguardhome
LOG="$DATA/daemon.log"
AGH=/data/adb/modules/adguardhome/system/bin/AdGuardHome
DNS_PORT=5353
HOTSPOT_IF=br0

mkdir -p "$DATA"

# bin-utils v1.3.0+ is a hard requirement (customize.sh enforces this).
. /data/adb/modules/bin-utils/lib/common.sh

# Go reads its own CA pool — Android's system pool isn't trusted out of
# the box, so DoH upstreams + blocklist downloads need SSL_CERT_FILE.
CA=$(find_ca_bundle) && export SSL_CERT_FILE="$CA"

# Wait for the hotspot bridge before installing iptables rules.
if wait_for_iface "$HOTSPOT_IF" 90 3; then
    log_line "$HOTSPOT_IF is up"
else
    log_line "$HOTSPOT_IF never came up within 90 s — will add rules anyway"
fi

ensure_iptables_redirect "$HOTSPOT_IF" udp 53 "$DNS_PORT"
ensure_iptables_redirect "$HOTSPOT_IF" tcp 53 "$DNS_PORT"
log_line "iptables: REDIRECT $HOTSPOT_IF udp+tcp/53 -> :$DNS_PORT at pos 1"

# Re-assert every 5 min in case ZTE firmware or netd reorders PREROUTING.
(
    while true; do
        sleep 300
        ensure_iptables_redirect "$HOTSPOT_IF" udp 53 "$DNS_PORT"
        ensure_iptables_redirect "$HOTSPOT_IF" tcp 53 "$DNS_PORT"
    done
) &

# Supervisor loop. We don't use supervisor_loop from common.sh here
# because we want to capture rc per cycle for diagnostics.
(
    while true; do
        log_rotate 524288
        log_line "starting AdGuardHome (work dir: $DATA)"
        "$AGH" --no-check-update --work-dir "$DATA" \
               --config "$DATA/AdGuardHome.yaml" >> "$LOG" 2>&1
        log_line "AdGuardHome exited rc=$?, restarting in 15 s"
        sleep 15
    done
) &

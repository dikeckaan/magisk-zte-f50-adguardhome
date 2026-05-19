#!/system/bin/sh
# AdGuard Home daemon supervisor.
#
# - Launches AdGuardHome with working dir /data/adguardhome
# - Hijacks hotspot DNS by inserting an iptables REDIRECT at the TOP of the
#   nat PREROUTING chain. The ZTE firmware adds its own DNAT-to-1.1.1.1 rule
#   on boot; we don't delete it (preserves vendor behaviour for tun0 / VPN
#   interfaces) but our rule is inserted before it so br0 traffic matches
#   first. iptables uses first-match, so this is a clean override.
# - Auto-restarts on crash. Log at /data/adguardhome/daemon.log.

DATA=/data/adguardhome
LOG="$DATA/daemon.log"
AGH=/data/adb/modules/adguardhome/system/bin/AdGuardHome
DNS_PORT=5353
HOTSPOT_IF=br0

mkdir -p "$DATA"

log_line() { echo "[$(date)] $*" >> "$LOG"; }

# Go reads its own CA pool — Android's system pool isn't trusted out of the box.
# Point Go at the bin-utils CA bundle (or /system/etc/cacert.pem as a fallback)
# so DoH upstreams and blocklist updates can verify TLS certificates.
for CABUNDLE in /data/adb/modules/bin-utils/system/etc/cacert.pem \
                /system/etc/cacert.pem \
                /system/etc/security/cacerts.bks; do
    [ -r "$CABUNDLE" ] && export SSL_CERT_FILE="$CABUNDLE" && break
done

# Wait for the hotspot bridge to come up. Up to 90 s, sampling every 3 s.
# The bridge appears as soon as tethering is enabled (often a few seconds
# into late_start, sometimes later if the user enables it manually).
wait_for_bridge() {
    local i=0
    while [ $i -lt 30 ]; do
        if ip link show "$HOTSPOT_IF" >/dev/null 2>&1; then
            log_line "$HOTSPOT_IF is up (waited ${i}x3s)"
            return 0
        fi
        sleep 3
        i=$((i+1))
    done
    log_line "$HOTSPOT_IF never came up within 90 s — will add rules anyway"
    return 1
}
wait_for_bridge

# Ensure our REDIRECT sits at position 1 of nat PREROUTING. Idempotent:
# delete any existing copy first (avoids duplicates), then insert at the top.
ensure_redirect() {
    local proto="$1"
    iptables -t nat -D PREROUTING -i "$HOTSPOT_IF" -p "$proto" --dport 53 \
             -j REDIRECT --to-ports "$DNS_PORT" 2>/dev/null
    if iptables -t nat -I PREROUTING 1 -i "$HOTSPOT_IF" -p "$proto" \
                --dport 53 -j REDIRECT --to-ports "$DNS_PORT" 2>/dev/null; then
        log_line "iptables: inserted $HOTSPOT_IF $proto/53 -> :$DNS_PORT at position 1"
    else
        log_line "iptables: FAILED to insert $proto rule (proto=$proto)"
    fi
}
ensure_redirect udp
ensure_redirect tcp

# Re-assert the redirect every 5 min in case the ZTE firmware (or any
# network state change) reorders PREROUTING. Cheap: just deletes-and-reinserts.
(
    while true; do
        sleep 300
        ensure_redirect udp
        ensure_redirect tcp
    done
) &

# Supervisor loop
(
    while true; do
        echo "[$(date)] starting AdGuardHome (work dir: $DATA)" >> "$LOG"
        "$AGH" --no-check-update --work-dir "$DATA" \
               --config "$DATA/AdGuardHome.yaml" >> "$LOG" 2>&1
        rc=$?
        echo "[$(date)] AdGuardHome exited rc=$rc, restarting in 15 s" >> "$LOG"
        sz=$(stat -c %s "$LOG" 2>/dev/null || echo 0)
        [ "$sz" -gt 524288 ] && mv "$LOG" "$LOG.1"
        sleep 15
    done
) &

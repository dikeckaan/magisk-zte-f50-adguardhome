#!/system/bin/sh
# AdGuard Home daemon supervisor.
#
# - Launches AdGuardHome with working dir /data/adguardhome
# - Adds iptables NAT redirect on br0 so hotspot clients hit AGH transparently
#   (br0:53 -> 127.0.0.1:5353). Device itself keeps using the system resolver.
# - Auto-restarts on crash. Log at /data/adguardhome/daemon.log.

DATA=/data/adguardhome
LOG="$DATA/daemon.log"
AGH=/data/adb/modules/adguardhome/system/bin/AdGuardHome
DNS_PORT=5353

mkdir -p "$DATA"

# Warm-up: let interfaces come up before adding NAT rules
sleep 25

# Add transparent NAT redirect on the hotspot bridge if not already present.
add_redirect() {
    local proto="$1"
    if ! iptables -t nat -C PREROUTING -i br0 -p "$proto" --dport 53 \
            -j REDIRECT --to-ports "$DNS_PORT" 2>/dev/null; then
        iptables -t nat -A PREROUTING -i br0 -p "$proto" --dport 53 \
            -j REDIRECT --to-ports "$DNS_PORT" 2>/dev/null \
            && echo "[$(date)] iptables: redirected br0 $proto/53 -> $DNS_PORT" >> "$LOG"
    fi
}
add_redirect udp
add_redirect tcp

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

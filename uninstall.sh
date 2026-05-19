#!/system/bin/sh
# Stop the daemon, kill the supervisor + the iptables-keepalive loop, and
# remove our REDIRECT rules. ZTE's DNAT-to-1.1.1.1 rules are NOT touched —
# they were there before us and continue to handle non-br0 DNS forwarding.
#
# /data/adguardhome/ (config, querylog, stats) is KEPT — wipe manually if you
# want a clean slate:  rm -rf /data/adguardhome

pkill -f /data/adb/modules/adguardhome/system/bin/AdGuardHome 2>/dev/null
pkill -f /data/adb/modules/adguardhome/service.sh 2>/dev/null

# Remove every copy of our redirect (the keepalive may have reinserted it
# multiple times across boots, so loop until -D fails).
while iptables -t nat -D PREROUTING -i br0 -p udp --dport 53 \
        -j REDIRECT --to-ports 5353 2>/dev/null; do :; done
while iptables -t nat -D PREROUTING -i br0 -p tcp --dport 53 \
        -j REDIRECT --to-ports 5353 2>/dev/null; do :; done

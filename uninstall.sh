#!/system/bin/sh
# Stop the daemon and remove the iptables redirect.
# /data/adguardhome/ (config, querylog, stats) is KEPT — wipe manually if you
# want a clean slate:  rm -rf /data/adguardhome
pkill -f /data/adb/modules/adguardhome/system/bin/AdGuardHome 2>/dev/null
pkill -f /data/adb/modules/adguardhome/service.sh 2>/dev/null

iptables -t nat -D PREROUTING -i br0 -p udp --dport 53 -j REDIRECT --to-ports 5353 2>/dev/null
iptables -t nat -D PREROUTING -i br0 -p tcp --dport 53 -j REDIRECT --to-ports 5353 2>/dev/null

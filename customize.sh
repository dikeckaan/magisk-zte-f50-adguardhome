#!/system/bin/sh
ui_print " "
ui_print "  AdGuard Home (DNS ad-blocker)"
ui_print "  ============================="
ui_print " "
ui_print "  Network-wide DNS-level ad blocking."
ui_print "  Daemon listens on UDP/TCP 5353 (no clash with dnsmasq:53)."
ui_print "  Hotspot clients are transparently redirected via iptables NAT."
ui_print "  Web UI:  http://192.168.0.1:3000"
ui_print "  Default login is set by first-run wizard at the web UI."
ui_print " "

# arm64 only
if [ "$ARCH" != "arm64" ]; then
    abort "  AdGuard Home binary is arm64-only. Aborting."
fi

# Work dir for config / data
mkdir -p /data/adguardhome
chmod 755 /data/adguardhome

# Seed config on first install (skip if user already has one)
if [ ! -f /data/adguardhome/AdGuardHome.yaml ]; then
    ui_print "  Seeding initial AdGuardHome.yaml (DNS=5353, Web=3000)..."
    cp "$MODPATH/AdGuardHome.yaml.template" /data/adguardhome/AdGuardHome.yaml
    chmod 600 /data/adguardhome/AdGuardHome.yaml
else
    ui_print "  Keeping existing /data/adguardhome/AdGuardHome.yaml"
fi

set_perm "$MODPATH/system/bin/AdGuardHome"  0 0 0755
set_perm "$MODPATH/service.sh"              0 0 0755

ui_print " "
ui_print "  [OK] Installed."
ui_print "  Reboot to start the daemon, or invoke service.sh manually."
ui_print "  Tip: open http://192.168.0.1:3000 from a hotspot client to"
ui_print "       finish the first-run wizard. Web port = 3000, DNS = 5353."
ui_print " "

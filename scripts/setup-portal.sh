#!/bin/bash
# Setup Captive Portal for initial configuration

set -e

echo "Setting up Captive Portal..."

# Determine the wireless interface
WIRELESS_IF=$(ls /sys/class/net | grep -E '^wlan' | head -n1)

if [ -z "$WIRELESS_IF" ]; then
    echo "No wireless interface found, skipping captive portal setup"
    exit 0
fi

echo "Using wireless interface: $WIRELESS_IF"

# Configure hostapd for access point
cat > /etc/hostapd/hostapd.conf <<EOF
# PrintALaPi Access Point Configuration
interface=$WIRELESS_IF
driver=nl80211
ssid=PrintALaPi-Setup
hw_mode=g
channel=7
wmm_enabled=0
macaddr_acl=0
auth_algs=1
ignore_broadcast_ssid=0
wpa=2
wpa_passphrase=printalapy
wpa_key_mgmt=WPA-PSK
wpa_pairwise=TKIP
rsn_pairwise=CCMP
EOF

# Configure dnsmasq for DHCP and DNS
cat > /etc/dnsmasq.conf <<EOF
# PrintALaPi DNS and DHCP Configuration
interface=$WIRELESS_IF
dhcp-range=192.168.4.2,192.168.4.20,255.255.255.0,24h
domain=printalapy.local
address=/#/192.168.4.1
EOF

# Configure network interface
cat > /etc/network/interfaces.d/$WIRELESS_IF <<EOF
auto $WIRELESS_IF
iface $WIRELESS_IF inet static
    address 192.168.4.1
    netmask 255.255.255.0
EOF

# Enable IP forwarding
sed -i 's/#net.ipv4.ip_forward=1/net.ipv4.ip_forward=1/' /etc/sysctl.conf
sysctl -p 2>/dev/null || echo "Note: sysctl changes will apply on first boot"

# Configure iptables for NAT
# Get the ethernet interface
ETH_IF=$(ls /sys/class/net | grep -E '^eth' | head -n1)

if [ -n "$ETH_IF" ]; then
    iptables -t nat -A POSTROUTING -o $ETH_IF -j MASQUERADE 2>/dev/null || echo "Note: iptables rules will be set on first boot"
    iptables -A FORWARD -i $ETH_IF -o $WIRELESS_IF -m state --state RELATED,ESTABLISHED -j ACCEPT 2>/dev/null || true
    iptables -A FORWARD -i $WIRELESS_IF -o $ETH_IF -j ACCEPT 2>/dev/null || true
    
    # Save iptables rules
    iptables-save > /etc/iptables.ipv4.nat 2>/dev/null || true
    
    # Restore iptables rules on boot
    cat >> /etc/rc.local <<'RCEOF'
#!/bin/sh -e
iptables-restore < /etc/iptables.ipv4.nat
exit 0
RCEOF
    chmod +x /etc/rc.local
fi

# Enable services
systemctl unmask hostapd || true
systemctl enable hostapd || true
systemctl enable dnsmasq || true

# Don't start yet - will start after reboot
echo "Captive portal configuration complete"

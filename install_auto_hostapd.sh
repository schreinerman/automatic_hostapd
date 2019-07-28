#!/bin/sh
apt-get update
apt-get -y install dnsmasq hostapd
mkdir /etc/io-expert
mkdir /etc/io-expert/startup


cat << EOF >/etc/io-expert/startup/01_hostap_wpasupplicant_switch
#!/bin/sh
RED='\033[0;31m'
NC='\033[0m'
GRN='\033[0;32m'

_APIP="192.168.40.1"  # change this to whatever you've set in dnsmasq
_WLAN_DEVICE="wlan0"  # change this to whatever your wlan device is (wlan0, etc)
_SHORT_HOST=\$(hostname)
_ETH=\$(ifconfig | grep eth)

_IP=\$(hostname -I) || true

if [ "\$_IP" ]; then
  printf "IP already set..."
else
  printf "No IP set... waiting 20s"
  sleep 20
fi


_IP=\$(hostname -I) || true
if [ "\$_IP" ]; then
  printf "My IP address is %s\n" "\$_IP"
else
    printf "No network interface has come up so let's configure the access point\n"

    ifdown \$_WLAN_DEVICE
    sleep 8

    printf "Bringing up hostapd\n"
    service hostapd restart
    sleep 8

    printf "Configuring wlan interface\n"
    ifconfig \$_WLAN_DEVICE \$_APIP
    sleep 8

    printf "Configuring DNSMasq\n"
    service dnsmasq restart
    sleep 8

    printf "You should now have an access point\n"
fi
EOF

cat << EOF >/etc/hostapd.conf
# BASICS
interface=wlan0
driver=nl80211
ssid=ioSmartScopeServer
hw_mode=g
channel=6

# DRAFT-N
ieee80211n=1
ht_capab=[DSSS_CCK-40][MAX-AMSDU-3839]
wmm_enabled=1

# COUNTRY
country_code=DE
ieee80211d=1

# WPA
macaddr_acl=0
auth_algs=1
ignore_broadcast_ssid=0
wpa=2
wpa_passphrase=smartscope2019!
wpa_key_mgmt=WPA-PSK
wpa_pairwise=TKIP
rsn_pairwise=CCMP
EOF

cat << EOF >/etc/rc.local
#!/bin/sh -e
#
# rc.local
#
# This script is executed at the end of each multiuser runlevel.
# Make sure that the script will "exit 0" on success or any other
# value on error.
#
# In order to enable or disable this script just change the execution
# bits.
#
# By default this script does nothing.

# Print the IP address
_IP=\$(hostname -I) || true
if [ „\$_IP" ]; then
  printf "My IP address is %s\n" „\$_IP"
fi

run-parts /etc/io-expert/startup

exit 0
EOF

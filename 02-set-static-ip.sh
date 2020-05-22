IP="192.168.117.5"
GATEWAY="192.168.117.1"
DNS="192.168.117.1"
LAN_INTERFACE="$(ls /sys/class/net | grep -m 1 -oP "en[a-z0-9]*")"

yes | pacman -S openresolv netctl #dialog wpa_supplicant

echo "Description='A basic static ethernet connection'" > /etc/netctl/ethernet-static
echo "Interface=${LAN_INTERFACE}" >> /etc/netctl/ethernet-static
echo "Connection=ethernet" >> /etc/netctl/ethernet-static
echo "IP=static" >> /etc/netctl/ethernet-static
echo "Address=('${IP}/24')" >> /etc/netctl/ethernet-static
echo "Gateway='${GATEWAY}'" >> /etc/netctl/ethernet-static
echo "DNS=('${DNS}')" >> /etc/netctl/ethernet-static


systemctl disable dhcpcd
netctl enable ethernet-static

**How to clear ip addr, link**\
ip link delete vxlan2\
ip addr del 192.168.0.55/24 dev vxlan2\
**VxLAN setup**\
**Machine 1**\
ip link add vxlan1 type vxlan id 1 remote 192.168.18.48 dstport 4789 dev wlp2s0\
ip link set vxlan1 up\
ip addr add 192.168.0.6/24 dev vxlan1\
**Machine 2**\
ip link add vxlan1 type vxlan id 1 remote 192.168.18.24 dstport 4789 dev wlp3s0\
ip link set vxlan1 up\
ip addr add 192.168.0.2/24 dev vxlan1\
**VxLAN in VxLAN**\
**Machine 1**\
ip link add vxlan1 type vxlan id 1 remote 192.168.18.48 dstport 4789 dev wlp2s0\
ip link set vxlan1 up\
ip addr add 192.168.0.6/24 dev vxlan1\
ip link add vxlan2 type vxlan id 55 remote 192.168.0.2 dstport 4789 dev vxlan1\
ip link set vxlan2 up\
ip addr add 192.168.12.55/24 dev vxlan2\
**Machine 2**\
ip link add vxlan1 type vxlan id 1 remote 192.168.18.24 dstport 4789 dev wlp3s0\
ip link set vxlan1 up\
ip addr add 192.168.0.2/24 dev vxlan1\
ip link add vxlan2 type vxlan id 55 remote 192.168.0.6 dstport 4789 dev vxlan1\
ip link set vxlan2 up\
ip addr add 192.168.12.77/24 dev vxlan2\
\
**VLAN setup**\
**machine 1**\
ip link add link wlp2s0 name eth0.100 type vlan id 100\
ip addr add 192.168.100.1/24 brd 192.168.100.255 dev eth0.100\
ip link set dev eth0.100 up\
**Machine2**\
ip link add link wlp3s0 name eth0.100 type vlan id 100\
ip addr add 192.168.100.2/24 brd 192.168.100.255 dev eth0.100\
ip link set dev eth0.100 up\
**Stacked VLAN (VLAN in VLAN, 8100,8100)**\
**Machine 1**\
ip link add link wlp2s0 name eth0.100 type vlan id 100\
ip addr add 192.168.100.1/24 brd 192.168.100.255 dev eth0.100\
ip link set dev eth0.100 up\
ip link add link eth0.100 name eth0.101 type vlan id 101\
ip addr add 192.168.101.1/24 brd 192.168.101.255 dev eth0.101\
ip link set dev eth0.101 up\
**machine 2**\
ip link add link wlp3s0 name eth0.100 type vlan id 100\
ip addr add 192.168.100.2/24 brd 192.168.100.255 dev eth0.100\
ip link set dev eth0.100 up\
ip link add link eth0.100 name eth0.101 type vlan id 101\
ip addr add 192.168.101.2/24 brd 192.168.101.255 dev eth0.101\
ip link set dev eth0.101 up\
**Stacked VLAN (S-tag, C-tag)**\
**Machine 1**\
ip link add link wlp2s0 eth0.11 type vlan proto 802.1ad id 11\
ip addr add 192.168.125.1/24 brd 192.168.125.255 dev eth0.11\
ip link set dev eth0.11 up\
ip link add link eth0.11 eth0.11.46 type vlan proto 802.1Q id 46\
ip addr add 192.168.116.1/24 brd 192.168.126.255 dev eth0.11.46\
ip link set dev eth0.11.46 up\
**machine 2**\
ip link add link wlp3s0 eth0.11 type vlan proto 802.1ad id 11\
ip addr add 192.168.125.2/24 brd 192.168.125.255 dev eth0.11\
ip link set dev eth0.11 up\
ip link add link eth0.11 eth0.11.46 type vlan proto 802.1Q id 46\
ip addr add 192.168.116.2/24 brd 192.168.126.255 dev eth0.11.46\
ip link set dev eth0.11.46 up\
**Captured traffic in pcap format**\
https://drive.google.com/drive/folders/1ZRJZFUXvBkZbRkMTFwXPEXNwhIcw-xOC?usp=sharing

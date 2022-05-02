#!/bin/bash
lxc init images:ubuntu/focal ctest
lxc config device add ctest eth0 nic nictype=macvlan parent=enp0s3
# lxc config device remove ctest eth0
lxc start ctest
lxc exec ctest -- ping 192.168.1.1
# udp port 34014 unreachable, length 132
# https://discuss.linuxcontainers.org/t/container-cant-ping-to-gateway/9370/17
# https://www.nakivo.com/blog/virtualbox-network-setting-guide/
# https://forums.virtualbox.org/viewtopic.php?f=35&t=96608
# https://blog.simos.info/how-to-make-your-lxd-container-get-ip-addresses-from-your-lan/comment-page-1/
# https://discuss.linuxcontainers.org/t/lxd-and-macvlan-help-me/1910/17
# https://discuss.linuxcontainers.org/t/vbox-nat-network-to-lxc-container/7115

# https://ilearnedhowto.wordpress.com/2016/09/16/how-to-create-a-overlay-network-using-open-vswitch-in-order-to-connect-lxc-containers/
# https://ilearnedhowto.wordpress.com/2016/09/21/how-to-connect-complex-networking-infrastructures-with-open-vswitch-and-lxc-containers/
# install lxd
sudo snap install lxd
# Add an existing user to group lxd.
sudo adduser $(whoami) lxd
# Change the current group ID during a login session.
newgrp lxd
sudo lxd init

# install openvswitch
apt-get install openvswitch-switch

lxc profile copy default bridge
lxc profile edit bridge
lxc profile assign c1 bridge

cat >/tmp/bridge.profile <<__EOF__
config: {}
description: LXD bridge profile
devices:
  eth0:
    name: eth0
    nictype: bridged
    parent: br-cont0
    type: nic
    mtu: 1400
  root:
    path: /
    pool: default
    type: disk
name: bridge
used_by: []
__EOF__

cat >/tmp/config.yaml <<__EOF__
config: {}
devices:
  eth0:
    name: eth0
    nictype: bridged
    parent: br-cont0
    type: nic
    mtu: 1400
__EOF__

################### nfs-server start ############################
brctl addbr br-cont0
ip l set br-cont0 up

lxc init images:alpine/edge c1 </tmp/config.yaml
lxc start c1

lxc exec c1 -- ip addr add 10.2.1.11/24 dev eth0

cat >/etc/network/interfaces <<__EOF__
auto eth0
iface eth0 inet static
address 10.2.1.11
netmask 255.255.255.0
mtu 1400
hostname $(hostname)
__EOF__

lxc config show c1 --expanded

lxc init images:alpine/edge c2 </tmp/config.yaml
lxc profile assign c2 bridge
lxc start c2

lxc exec c2 -- ip addr add 10.2.1.12/24 dev eth0
cat >/etc/network/interfaces <<__EOF__
auto eth0
iface eth0 inet static
address 10.2.1.12
netmask 255.255.255.0
mtu 1400
hostname $(hostname)
__EOF__

# openvswitch setting
ovs-vsctl add-br ovsbr0
ovs-vsctl add-port ovsbr0 br-cont0
# ovs-vsctl del-port ovsbr0 br-cont0

ovs-vsctl add-port ovsbr0 vxlan0 -- set interface vxlan0 type=vxlan options:remote_ip=192.168.56.4

###### setup dhcp server start ######
brctl addbr br-out
ip addr add dev br-out 10.0.1.1/24
ip l set br-out up
cat >/tmp/enable_nat.sh <<'__EOF__'
set -ex
#!/bin/bash
export IFACE_WAN=enp0s3
export IFACE_LAN=br-out
export NETWORK_LAN=10.0.1.0/24

echo "1" > /proc/sys/net/ipv4/ip_forward
iptables -t nat -A POSTROUTING -o "$IFACE_WAN" -s "$NETWORK_LAN" ! -d "$NETWORK_LAN" -j MASQUERADE
iptables -A FORWARD -d "$NETWORK_LAN" -i "$IFACE_WAN" -o "$IFACE_LAN" -m state --state RELATED,ESTABLISHED -j ACCEPT
iptables -A FORWARD -s "$NETWORK_LAN" -i "$IFACE_LAN" -j ACCEPT
__EOF__
chmod +x /tmp/enable_nat.sh
bash /tmp/enable_nat.sh

cat >/tmp/dhcp-config.yaml <<__EOF__
config: {}
devices:
  eth0:
    name: eth0
    nictype: bridged
    parent: br-out
    type: nic
__EOF__
lxc init images:alpine/edge dhcpserver </tmp/dhcp-config.yaml
lxc start dhcpserver
lxc exec dhcpserver -- ash -c 'echo "nameserver 8.8.8.8" > /etc/resolv.conf
ip addr add 10.0.1.2/24 dev eth0
ip r add default via 10.0.1.1
sed -i "s/dl-cdn.alpinelinux.org/mirrors.ustc.edu.cn/g" /etc/apk/repositories
apk add dnsmasq
rc-update add dnsmasq
rc-service start dnsmasq
rc-service --list | grep dnsmasq
cat > /etc/network/interfaces <<__EOF__
auto eth0
iface eth0 inet static
address 10.2.1.202
netmask 255.255.255.0
mtu 1400
hostname $(hostname)
__EOF__

# https://wiki.archlinux.org/title/dnsmasq
# https://www.tecmint.com/setup-a-dns-dhcp-server-using-dnsmasq-on-centos-rhel/
# https://fedoramagazine.org/dnsmasq-provide-dns-dhcp-services/
# https://github.com/imp/dnsmasq/blob/master/dnsmasq.conf.example
cat > /etc/dnsmasq.conf << __EOF__
interface=eth0
except-interface=lo
listen-address=10.2.1.202
bind-interfaces
dhcp-range=10.2.1.1,10.2.1.200,1h
dhcp-option=26,1400
dhcp-option=option:router,10.2.1.201
# Set DNS servers to announce
dhcp-option=6,8.8.8.8,8.8.4.4
no-resolv
expand-hosts
domain=neo.chen

# Googles nameservers, for example
# server=8.8.8.8
# server=8.8.4.4
__EOF__

rc-service dnsmasq restart
'
cat >/tmp/dhcp-config.yaml <<__EOF__
config: {}
devices:
  eth0:
    name: eth0
    nictype: bridged
    parent: br-cont0
    type: nic
__EOF__
lxc config show dhcpserver --expanded

# change back the eth0 parent from br-out to br-cont0
# we have already install dnsmasq, now we don't need any more internet access
lxc config device set dhcpserver eth0 parent=br-cont0
lxc restart dhcpserver
lxc exec dhcpserver -- ash -c '
# restart the networking
rc-service networking restart
# verify the static ip address setting from the /etc/network/interfaces
ip a
'
###### setup dhcp server end ######

###### setup router start ######
cat >/tmp/router-config.yaml <<__EOF__
config: {}
devices:
  eth0:
    name: eth0
    nictype: bridged
    parent: br-cont0
    type: nic
  eth1:
    name: eth1
    nictype: bridged
    parent: br-out
    type: nic
__EOF__

lxc init images:alpine/edge router </tmp/router-config.yaml
lxc start router
lxc exec router -- ash -c '
cat > /etc/network/interfaces << __EOF__
auto lo
iface lo inet loopback

auto eth0
iface eth0 inet static
address 10.2.1.201
netmask 255.255.255.0

auto eth1
iface eth1 inet static
address 10.0.1.2
netmask 255.255.255.0
gateway 10.0.1.1

hostname $(hostname)
__EOF__
rc-service networking restart
ip a
sed -i "s/dl-cdn.alpinelinux.org/mirrors.ustc.edu.cn/g" /etc/apk/repositories
echo "nameserver 8.8.8.8" > /etc/resolv.conf

# https://wiki.alpinelinux.org/wiki/Configure_Networking#Configure_iptables.2Fip6tables
apk add iptables
# rc-update add iptables 

cat > /tmp/enable_nat.sh << '__EOF__'
set -ex
#!/bin/bash
export IFACE_WAN=eth1
export IFACE_LAN=eth0
export NETWORK_LAN=10.2.1.0/24

echo "1" > /proc/sys/net/ipv4/ip_forward
iptables -t nat -A POSTROUTING -o "$IFACE_WAN" -s "$NETWORK_LAN" ! -d "$NETWORK_LAN" -j MASQUERADE
iptables -A FORWARD -d "$NETWORK_LAN" -i "$IFACE_WAN" -o "$IFACE_LAN" -m state --state RELATED,ESTABLISHED -j ACCEPT
iptables -A FORWARD -s "$NETWORK_LAN" -i "$IFACE_LAN" -j ACCEPT
__EOF__
chmod +x /tmp/enable_nat.sh
/tmp/enable_nat.sh
'

lxc restart c1
lxc restart c2
lxc exec router -- ash -c '
echo "nameserver 8.8.8.8" > /etc/resolv.conf
sed -i "s/dl-cdn.alpinelinux.org/mirrors.ustc.edu.cn/g" /etc/apk/repositories
apk add traceroute
# check the route
traceroute 4.2.2.2
'
###### setup router end ######

################### nfs-server end ############################

################### nfs-client start ############################
brctl addbr br-cont0
ip l set br-cont0 up

lxc init images:alpine/edge c1 </tmp/config.yaml
lxc profile assign c1 bridge
lxc start c1

lxc exec c1 -- ip addr add 10.2.1.21/24 dev eth0
cat >/etc/network/interfaces <<__EOF__
auto eth0
iface eth0 inet static
address 10.2.1.21
netmask 255.255.255.0
mtu 1400
hostname $(hostname)
__EOF__

lxc init images:alpine/edge c2 </tmp/config.yaml
lxc profile assign c2 bridge
lxc start c2

lxc exec c2 -- ip addr add 10.2.1.22/24 dev eth0
cat >/etc/network/interfaces <<__EOF__
auto eth0
iface eth0 inet static
address 10.2.1.22
netmask 255.255.255.0
mtu 1400
hostname $(hostname)
__EOF__

lxc init images:alpine/edge c3 </tmp/config.yaml
lxc start c3
lxc exec c3 -- ash -c '
cat > /etc/network/interfaces <<__EOF__
auto eth0
iface eth0 inet dhcp
hostname $(hostname)
__EOF__
rc-service networking restart
'
# openvswitch setting
ovs-vsctl add-br ovsbr0
ovs-vsctl add-port ovsbr0 br-cont0
# ovs-vsctl del-port ovsbr0 br-cont0
ovs-vsctl add-port ovsbr0 vxlan0 -- set interface vxlan0 type=vxlan options:remote_ip=192.168.56.3

# after the dhcpserver and router setting ok
# test our mtu setup
# http://www.microhowto.info/howto/change_the_mtu_of_a_network_interface.html
ping -M do -c 4 -s 8972 10.2.1.201
# Path MTUs are recorded in the routing cache. This can interfere with testing
ip route flush cache

# dig equaliv
apk add drill
# Then use it as you would for dig:
drill alpinelinux.org @8.8.8.8
# To perform a reverse lookup (get a name from an IP) use the following syntax:
drill -x 8.8.8.8 @208.67.222.222
################### nfs-client end ############################

sudo tcpdump -i enp0s8 'host 192.168.56.4' -w ovs-vxlan-ping.pcap -nn

### nfs-server config ###
cat >/etc/netplan/50-vagrant.yaml <<__EOF__
---
network:
  version: 2
  renderer: networkd
  ethernets:
    enp0s8:
      addresses:
      - 192.168.56.3/24
__EOF__

### nfs-clinet config ###
cat >/etc/netplan/50-vagrant.yaml <<__EOF__
---
network:
  version: 2
  renderer: networkd
  ethernets:
    enp0s8:
      addresses:
      - 192.168.56.4/24
__EOF__

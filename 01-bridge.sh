#!/bin/bash
ip link add netns c1
ip link add veth1 type veth peer name veth1_p
ip addr add 10.0.0.2/24 dev veth1
ip link set veth1 netns c1
ip netns exec c1 ip link set veth1 up

# add br0
brctl addbr br0
ip addr add 10.0.0.1/24 dev br0
ip link set veth1_p master br0
ip link set veth1_p up
ip link set br0 up

# add default gw
ip route add default via 10.0.0.1
#route add default gw 10.0.0.1 veth1


# turn on ip-forwarding on host
sysctl net.ipv4.conf.all.forwarding=1
iptables -P FORWARD ACCEPT

# turn on POSTROUTING when access the internet
iptables -t nat -A POSTROUTING ! -o br0 -s 10.0.0.0/24 -j MASQUERADE

# turn on PREROUTING for external ip to access the c1 service
iptables -t nat -A PREROUTING ! -i br0 -D 10.0.0.0/24 -p tcp -m tcp --dport 8080 -j DNAT --to-destination 10.0.0.2:8080

# check the newly configured iptables
iptables -t nat -nvL

# enter the given netns to test
ip netns exec c1 /bin/bash

# configure the resolv.conf to access the dns
mkdir /etc/netns/c1/ && cp /etc/resolv.conf /etc/netns/c1/
sed  -i "s/nameserver 127.0.0.53/nameserver 8.8.8.8/" /etc/netns/c1/resolv.conf

# test the dns
ping www.baidu.com


# check the syscall access point when exec at the given netns
strace  -f ip netns exec c1 sleep 1 2>&1|egrep '/etc/|clone|mount|unshare'|egrep -vw '/etc/ld.so|access'

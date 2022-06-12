#!/bin/sh
# https://mp.weixin.qq.com/s/Dc671aQzjlHWW37dNszdMg

ip netns add c1
ip netns add c2

ip netns exec c1 ip l set lo up
ip netns exec c2 ip l set lo up

ip l add veth0 type veth peer name ceth0
ip l add veth1 type veth peer name ceth1

ip l add br0 type bridge
ip l set br0 up

ip l set ceth0 netns c1
ip l set ceth1 netns c2

ip netns exec c1 ip a add 10.0.1.101/24 dev ceth0
ip netns exec c1 ip l set dev ceth0 up

ip netns exec c2 ip a add 10.0.1.102/24 dev ceth1
ip netns exec c2 ip l set dev ceth1 up

ip l set veth0 master br0
ip l set dev veth0 up

ip l set veth1 master br0
ip l set dev veth1 up

# make the container comm to the host ip
ip a add local 10.0.1.1/24 dev br0

ip netns exec c1 ip r add default via 10.0.1.1
ip netns exec c2 ip r add default via 10.0.1.1

# we make cross vm container communicate with each other
ip r add 10.0.0.0/24 via 192.168.56.4

sysctl -w net.ipv4.ip_forward=1
iptables -t nat -A POSTROUTING ! -o br0 -s 10.0.1.0/24 -j MASQUERADE

ip netns exec c1 ping -c1 10.0.1.101
ip netns exec c1 ping -c1 10.0.1.102

ip netns exec c1 ping -c1 192.168.56.3
ip netns exec c1 ping -c1 192.168.56.4

ip netns exec c1 ping -c1 10.0.0.101
ip netns exec c1 ping -c1 10.0.0.102

ip netns exec c1 ping -c1 10.0.0.1
ip netns exec c1 ping -c1 10.0.1.1

ip netns exec c1 ping -c1 4.2.2.2


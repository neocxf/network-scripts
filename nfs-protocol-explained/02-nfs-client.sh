#!/bin/sh
# https://mp.weixin.qq.com/s/Dc671aQzjlHWW37dNszdMg

ip netns add c1
ip netns add c2

ip netns exec c1 ip l set lo up
ip netns exec c2 ip l set lo up

ip l add br0 type bridge
ip l set br0 up

ip l add veth1 type veth peer name ceth1
ip l add veth2 type veth peer name ceth2

ip l set ceth1 netns c1
ip l set ceth2 netns c2

ip netns exec c1 ip a add 10.0.0.101/24 dev ceth1
ip netns exec c1 ip l set dev ceth1 up

ip netns exec c2 ip a add 10.0.0.102/24 dev ceth2
ip netns exec c2 ip l set dev ceth2 up

ip l set veth1 master br0
ip l set dev veth1 up
ip l set veth2 master br0
ip l set dev veth2 up


ip l add vxlan1 type vxlan id 1 dev enp0s8 remote 192.168.56.3 dstport 9527
ip l set vxlan1 master br0
ip l set vxlan1 up



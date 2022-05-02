#!/bin/sh
# https://mp.weixin.qq.com/s/Dc671aQzjlHWW37dNszdMg

ip netns add c3
ip netns add c4

ip netns exec c3 ip l set lo up
ip netns exec c4 ip l set lo up

ip l add br0 type bridge
ip l set br0 up

ip l add veth3 type veth peer name ceth3
ip l add veth4 type veth peer name ceth4

ip l set ceth3 netns c3
ip l set ceth4 netns c4

ip netns exec c3 ip a add 10.0.0.103/24 dev ceth3
ip netns exec c3 ip l set dev ceth3 up

ip netns exec c4 ip a add 10.0.0.104/24 dev ceth4
ip netns exec c4 ip l set dev ceth4 up

ip l set veth3 master br0
ip l set dev veth3 up
ip l set veth4 master br0
ip l set dev veth4 up

ip l add vxlan2 type vxlan id 1 dev enp0s8 remote 192.168.56.4 dstport 9527
ip l set vxlan2 master br0
ip l set vxlan2 up

# ip netns del c3
# ip netns del c4
# ip l del br0
# ip l del veth3
# ip l del veth4

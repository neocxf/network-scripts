#!/bin/sh
# simple bridge, no stp, boradcast/multicast and promisc on
# to test the connectivity from the host to guest, enp0s8 has to be hostonly nic
# https://www.youtube.com/watch?v=zv9AS0FhQ-k
# https://github.com/moby/libnetwork/blob/master/docs/macvlan.md
# https://suhu0426.github.io/Web/Presentation/20150120/index.html
# https://nathanielho.com/docker/macvlan01.html
ip netns add ns1
ip netns add ns2

# ip link add link enp0s8 name macif1 type macvlan help 
ip link add link enp0s8 name macif1 type macvlan 

# show the default mode for macvlan
ip -d l show type macvlan

ip l del macif1

ip link add link enp0s8 name macif1 type macvlan mode bridge
ip link add link enp0s8 name macif2 type macvlan mode bridge
ip -d l show type macvlan

ip l set macif1 netns ns1
ip l set macif2 netns ns2

ip netns exec ns1 ip l set lo up
ip netns exec ns1 ip l set macif1 up
ip netns exec ns1 ip a add 192.168.100.100/24 dev macif1

ip netns exec ns2 ip l set lo up
ip netns exec ns2 ip l set macif2 up
ip netns exec ns2 ip a add 192.168.100.110/24 dev macif2

ip netns exec ns1 ip -br l show
ip netns exec ns2 ip -br l show

ip netns exec ns1 ip -br a show
ip netns exec ns2 ip -br a show

# test connectivity from ns1 to ns2 or vice visa
ip netns exec ns1 ping -c1 192.168.100.110
ip netns exec ns2 ping -c1 192.168.100.100

# setup macif0 on host side
ip link add link enp0s8 name macif0 type macvlan mode bridge
ip l set macif0 up
ip a add 192.168.100.1/24 dev macif0

# test connectivity from ns1 to host or vice visa
ip netns exec ns1 ping -c1 192.168.100.1
ip netns exec ns2 ping -c1 192.168.100.1
ping -c1 192.168.100.100

# sniff the traffic
ip netns exec ns1 tcpdump -i macif1 -ln

# send the traffic
ping -c1 192.168.100.100


# from the vm host machine, let's say win10
route print
# assign a new ip address (192.168.100.10/24) for our hostonly nic
# add a new route entry
route add 192.168.100.0 mask 255.255.255.0 192.168.100.1
# test the connectivity from host to vm guest
ping -c1 192.168.100.1
# test the connectivity from host to vm guest namespace: ns1
ping -c1 192.168.100.100
# test the connectivity from host to vm guest namespace: ns2
ping -c1 192.168.100.110

# by default, none of the above will work, since the ns1's vnic mac will not match the enp0s8's mac address
# and whenever the enp0s8 say the mac address target to the ns1 or ns2, it will drop it 
# we can overcome this limit by two methods:
# 1. activate the master card's promiscuity mode: ip -d l set enp0s8 promisc on
# 2. activate the tcpdump process which inplicitly activate the enp0s8's promiscuity mode (you can verify it using `ip -d l show enp0s8`))
ip -d l set enp0s8 promisc on

# now the ping from host to vm guest (or vm ns) will work
ping -c1 192.168.100.1
ping -c1 192.168.100.100
ping -c1 192.168.100.110

#!/bin/sh
# refer: https://www.youtube.com/watch?v=FyV4MoQ3T0I
# emulate a single switch with 3 host connected to it, and with easy read mac address assigned to the host
sudo mn --topo=single,3 --no-controller --mac

sh ovs-ofctl show s1
# add our flow entry
# action means traditional L2-switch behavior
sh ovs-ofctl add-flow s1 action=normal

pingall

# add L1 flow entry based on the l1 in_port and out_port
# del the all flow entries for s1
sh ovs-ofctl del-flows s1

sh ovs-ofctl add-flow s1 priority=500,in_port=1,actions=output:2
sh ovs-ofctl add-flow s1 priority=500,in_port=2,actions=output:1

sh ovs-ofctl add-flow s1 priority=32768,actions=drop

sh ovs-ofctl dump-flows s1

# add L2 flow entry based on the l2 src and dst mac address
sh ovs-ofctl del-flows s1 --strict

sh ovs-ofctl del-flows s1
sh ovs-ofctl add-flow s1 dl_src=00:00:00:00:00:01,dl_dst=00:00:00:00:00:02,actions=output:2
sh ovs-ofctl add-flow s1 dl_src=00:00:00:00:00:02,dl_dst=00:00:00:00:00:01,actions=output:1

# add L2 arp request (unicast)
# 0x806: ethernet type for arp
# nw_proto: 1 means arp request
# flood: send out the packet all except the one received in
sh ovs-ofctl add-flow s1 dl_type=0x806,nw_proto=1,actions=flood

# L3 matching flow
sh ovs-ofctl del-flows s1
# 0x800: ethernet type for ip
# when using L3 type matching, either dl-type or ip has to be provided, otherwise the flow will be ignored
sh ovs-ofctl add-flow s1 priority=500,dl-type=0x800,nw_src=10.0.0.0/24,nw_dst=10.0.0.0/24,actions=normal
sh ovs-ofctl add-flow s1 priority=800,ip,nw_src=10.0.0.3,actions=mod_nw_tos:184,normal
sh ovs-ofctl add-flow s1 arp,nw_dst=10.0.0.1,actions=output:1
sh ovs-ofctl add-flow s1 arp,nw_dst=10.0.0.2,actions=output:2
sh ovs-ofctl add-flow s1 arp,nw_dst=10.0.0.3,actions=output:3

# L4 matching flow
sh ovs-ofctl del-flows s1
h3 python -m SimpleHTTPServer 80 &
sh ovs-ofctl add-flow s1 arp,action=normal
# 0x800: type for ip
# nw_proto: 6 means tcp
# tp_dst: 80 means the dst port number
sh ovs-ofctl add-flow s1 priority=500,dl_type=0x800,nw_proto=6,tp_dst=80,actions=output:3
sh ovs-ofctl add-flow s1 priority=500,ip,nw_src=10.0.0.3,actions=normal

# dl_type, nw_proto values and keywords (from ovs-ofctl MAN page):
# ip: dl_type=0x800
# arp:  dl_type=0x806
# (nw_proto=1 for requests,nw_proto=2 for replies)
# rarp: dl_type=0x8035
# icmp: dl_type=0x800,nw_proto=1
# tcp: dl_type=0x0800,nw_proto=6
# udp: dl_type=0x0800,nw_proto=17
# ipv6: dl_type=0x86dd
# tcp6: dl_type=0x86dd,nw_proto=6
# udp6: dl_type=0x86dd,nw_proto=17
# icmp6: dl_type=0x86dd,nw_proto=58

# Greatly explained how to implement OpenFlow entries to the Open vSwitches flow table (single flow table).
# Can be done many different ways, such as by certain interface, by layer1 method (in_port),
# by layer2 method (MAC address), by layer3 method (ip address), by layer4 method (TCP).
# Also, there are also many other parameters that can affect to flow entry contents.
# These can be done in Mininet CLI but I believe it is also possible to do by Python scripts.
# This shows why centralized routing is so useful.

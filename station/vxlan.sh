#!/bin/bash

ip l add vxlan1 type vxlan id 1 dev enp0s8 remote 192.168.65.100 dstport 8472
ip l set vxlan1 master docker0
ip l set vxlan1 up

ip l add vxlan2 type vxlan id 1 dev eth1 remote 192.168.65.200 dstport 8472
ip l set vxlan2 master docker0
ip l set vxlan2 up


sudo tcpdump -i any 'port 8472' -w vxlan-ping.pcap -nn
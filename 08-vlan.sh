#!/bin/bash
# https://foofunc.com/how-to-configure-vlan-network-in-ubuntu/

# add a vlan with tag 100
# enp0s8 in lan 192.168.65.0/24
sudo ip l add l enp0s8 name enp0s8.100 type vlan id 100
sudo ip l set enp0s8.100 up
sudo ip a add 192.168.100.2/24 dev enp0s8.100

# capature the traffic to another vlan tag 100's host
sudo tcpdump -i enp0s8.100 -w vlan100.pcap icmp and host 192.168.100.3

ping -c1 -I enp0s8.100 192.168.100.3

# eth1 in lan 192.168.65.0/24
sudo ip l add l eth1 name eth1.100 type vlan id 100
sudo ip l set eth1.100 up
sudo ip a add 192.168.100.3/24 dev eth1.100

ping -c1 -I eth1.100 192.168.100.2
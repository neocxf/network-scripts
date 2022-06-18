#!/bin/bash
# https://dustinspecker.com/posts/kubernetes-networking-from-scratch-bgp-bird-advertise-pod-routes/

# mount current directory to vm1 and vm2
multipass mount `pwd` vm1:~/scripts
multipass mount `pwd` vm2:~/scripts

multipass exec vm1 -- sudo scripts/setupvm1.sh
multipass exec vm1 -- sudo scripts/setupvm2.sh

# by default, without bridge_home, ARP requests from container will not be handled
# instead, we need enable the host veth nic's proxy_arp to make the connectivity to internet
# TCP/IP VOL1 p60
multipass exec vm1 -- sudo sysctl -w net.ipv4.conf.veth_dustin.proxy_arp=1
multipass exec vm1 -- sudo sysctl -w net.ipv4.conf.veth_dustin.proxy_arp=1


# ubuntu@vm1:~$ ip l show veth_dustin
# 4: veth_dustin@if3: <BROADCAST,MULTICAST,UP,LOWER_UP> mtu 1500 qdisc noqueue state UP mode DEFAULT group default qlen 1000
#     link/ether 5a:b0:e9:c7:6a:11 brd ff:ff:ff:ff:ff:ff link-netns netns_dustin
# ubuntu@vm1:~$ 

# root@vm1:/home/ubuntu/scripts# ip neigh
# 8.8.8.8 dev veth_ns_dustin lladdr 5a:b0:e9:c7:6a:11 STALE
# 4.2.2.2 dev veth_ns_dustin lladdr 5a:b0:e9:c7:6a:11 STALE
# 198.20.0.1 dev veth_ns_dustin lladdr 5a:b0:e9:c7:6a:11 STALE
# root@vm1:/home/ubuntu/scripts# 


# manual way to setup route
multipass exec vm1 -- sudo ip route add 10.0.1.0/24 via 198.20.0.2
multipass exec vm2 -- sudo ip route add 10.0.0.0/24 via 198.20.0.1

# let's manage the route automatically by bird2
multipass exec vm1 -- sudo ip route del 10.0.1.0/24 via 198.20.0.2
multipass exec vm2 -- sudo ip route del 10.0.0.0/24 via 198.20.0.1

multipass exec vm1 -- bash -c 'sudo apt update && sudo apt install bird2 --yes'
multipass exec vm2 -- bash -c 'sudo apt update && sudo apt install bird2 --yes'

multipass exec vm1 -- bash -c 'sudo cp -f scripts/vm1-bird.conf /etc/bird/bird.conf'
multipass exec vm2 -- bash -c 'sudo cp -f scripts/vm2-bird.conf /etc/bird/bird.conf'

multipass exec vm1 sudo systemctl restart bird
multipass exec vm2 sudo systemctl restart bird

# https://linuxhint.com/wireshark-command-line-interface-tshark/
# https://www.wireshark.org/docs/man-pages/wireshark-filter.html
multipass exec vm2 -- sudo tshark -i any -lnV host 10.0.1.11

multipass exec vm2 -- sudo tshark -i ens3  -lnV -c 2 -w scripts/ipip.pcap host 198.20.0.2
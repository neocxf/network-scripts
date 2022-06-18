#!/bin/sh

sudo sysctl --write net.ipv4.ip_forward=1

sudo ip link add dev bridge_home type bridge
sudo ip address add $BRIG_IP dev bridge_home

sudo ip netns add netns_dustin
sudo mkdir -p /etc/netns/netns_dustin
echo "nameserver 8.8.8.8" | sudo tee -a /etc/netns/netns_dustin/resolv.conf
sudo ip netns exec netns_dustin ip link set dev lo up
sudo ip link add dev veth_dustin type veth peer name veth_ns_dustin
sudo ip link set dev veth_dustin master bridge_home
sudo ip link set dev veth_dustin up
sudo ip link set dev veth_ns_dustin netns netns_dustin
sudo ip netns exec netns_dustin ip link set dev veth_ns_dustin up
sudo ip netns exec netns_dustin ip address add $C1_IP dev veth_ns_dustin

sudo ip netns add netns_leah
sudo mkdir -p /etc/netns/netns_leah
echo "nameserver 8.8.8.8" | sudo tee -a /etc/netns/netns_leah/resolv.conf
sudo ip netns exec netns_leah ip link set dev lo up
sudo ip link add dev veth_leah type veth peer name veth_ns_leah
sudo ip link set dev veth_leah master bridge_home
sudo ip link set dev veth_leah up
sudo ip link set dev veth_ns_leah netns netns_leah
sudo ip netns exec netns_leah ip link set dev veth_ns_leah up
sudo ip netns exec netns_leah ip address add $C2_IP dev veth_ns_leah

sudo ip link set bridge_home up
sudo ip netns exec netns_dustin ip route add default via $BRIG_GW
sudo ip netns exec netns_leah ip route add default via $BRIG_GW

# create iptable rules to allow traffic in and out bridge_home
sudo iptables --table filter --append FORWARD --in-interface bridge_home --jump ACCEPT
sudo iptables --table filter --append FORWARD --out-interface bridge_home --jump ACCEPT

# create masquerade requests from our customized namespace to out
sudo iptables --table nat --append POSTROUTING --source $BRIG_NET --jump MASQUERADE

# start a http server at netns_dustin
sudo ip netns exec netns_dustin python3 -m http.server 8080 &

# start a http server at netns_leah
sudo ip netns exec netns_leah python3 -m http.server 8080 &

# test the conectivity from host to netns and netns to netns
# curl 10.0.0.11:8080
# curl 10.0.0.21:8080
# sudo ip netns exec netns_dustin curl 10.0.0.21:8080
# sudo ip netns exec netns_leah curl 10.0.0.11:8080
# sudo ip netns exec netns_leah ping -c1 4.2.2.2

ip netns exec netns_dustin

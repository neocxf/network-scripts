#!/bin/sh

sudo sysctl --write net.ipv4.ip_forward=1

sudo ip netns add netns_dustin
sudo mkdir -p /etc/netns/netns_dustin
echo "nameserver 8.8.8.8" | sudo tee -a /etc/netns/netns_dustin/resolv.conf
sudo ip netns exec netns_dustin ip link set dev lo up
sudo ip link add dev veth_dustin type veth peer name veth_ns_dustin
sudo ip link set dev veth_dustin up
sudo ip link set dev veth_ns_dustin netns netns_dustin
sudo ip netns exec netns_dustin ip link set dev veth_ns_dustin up
sudo ip netns exec netns_dustin ip address add $C1_IP dev veth_ns_dustin
sudo ip netns exec netns_dustin ip r add default via $C1_HOST

sudo ip route add $C1_NET dev veth_dustin

# create iptable rules to allow traffic in and out bridge_home
sudo iptables --table filter --append FORWARD --in-interface ens3 --out-interface veth_dustin --jump ACCEPT
sudo iptables --table filter --append FORWARD --in-interface veth_dustin --out-interface ens3 --jump ACCEPT

# create masquerade requests from our customized namespace to out
sudo iptables --table nat --append POSTROUTING --out-interface ens3 --jump MASQUERADE

echo "enable proxy_arp feature of veth_dustin to allow the arp request to be proxied"
sudo sysctl -w net.ipv4.conf.veth_dustin.proxy_arp=1
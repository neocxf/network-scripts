#!/bin/bash
# Demo the kube-proxy iptables-mode

# in vm1
# first we need enable ip_forward
sudo sysctl --write net.ipv4.ip_forward=1

sudo ip link add dev bridge_home type bridge
sudo ip address add 10.0.0.1/24 dev bridge_home

sudo ip netns add netns_dustin
sudo mkdir -p /etc/netns/netns_dustin
echo "nameserver 8.8.8.8" | sudo tee -a /etc/netns/netns_dustin/resolv.conf
sudo ip netns exec netns_dustin ip link set dev lo up
sudo ip link add dev veth_dustin type veth peer name veth_ns_dustin
sudo ip link set dev veth_dustin master bridge_home
sudo ip link set dev veth_dustin up
sudo ip link set dev veth_ns_dustin netns netns_dustin
sudo ip netns exec netns_dustin ip link set dev veth_ns_dustin up
sudo ip netns exec netns_dustin ip address add 10.0.0.11/24 dev veth_ns_dustin

sudo ip netns add netns_leah
sudo mkdir -p /etc/netns/netns_leah
echo "nameserver 8.8.8.8" | sudo tee -a /etc/netns/netns_leah/resolv.conf
sudo ip netns exec netns_leah ip link set dev lo up
sudo ip link add dev veth_leah type veth peer name veth_ns_leah
sudo ip link set dev veth_leah master bridge_home
sudo ip link set dev veth_leah up
sudo ip link set dev veth_ns_leah netns netns_leah
sudo ip netns exec netns_leah ip link set dev veth_ns_leah up
sudo ip netns exec netns_leah ip address add 10.0.0.21/24 dev veth_ns_leah

sudo ip link set bridge_home up
sudo ip netns exec netns_dustin ip route add default via 10.0.0.1
sudo ip netns exec netns_leah ip route add default via 10.0.0.1

# create iptable rules to allow traffic in and out bridge_home
sudo iptables --table filter --append FORWARD --in-interface bridge_home --jump ACCEPT
sudo iptables --table filter --append FORWARD --out-interface bridge_home --jump ACCEPT

# create masquerade requests from our customized namespace to out
sudo iptables --table nat --append POSTROUTING --source 10.0.0.0/24 --jump MASQUERADE

# start a http server at netns_dustin
sudo ip netns exec netns_dustin python3 -m http.server 8080

# start a http server at netns_leah
sudo ip netns exec netns_leah python3 -m http.server 8080

# test the conectivity from host to netns and netns to netns
curl 10.0.0.11:8080
curl 10.0.0.21:8080
sudo ip netns exec netns_dustin curl 10.0.0.21:8080
sudo ip netns exec netns_leah curl 10.0.0.11:8080
sudo ip netns exec netns_leah ping -c1 4.2.2.2



# emulate VIP 10.100.100.100 (align to ClusterIP in k8s)

# add a new chain named DUSTIN-SERVICES
sudo iptables --table nat --new DUSTIN-SERVICES

# make PREROUTING and OUTPUT chain to pass through DUSTIN_SERVICES
sudo iptables \
  --table nat \
  --append PREROUTING \
  --jump DUSTIN-SERVICES

sudo iptables \
  --table nat \
  --append OUTPUT \
  --jump DUSTIN-SERVICES

# direct VIP traffic to our pod endpoint
sudo iptables \
  --table nat \
  --append DUSTIN-SERVICES \
  --destination 10.100.100.100 \
  --protocol tcp \
  --match tcp \
  --dport 8080 \
  --jump DNAT \
  --to-destination 10.0.0.11:8080

# VIP working. :) bingo
curl 10.100.100.100:8080

# may work or not
sudo ip netns exec netns_dustin curl 10.100.100.100:8080

sudo modprobe br_netfilter
sysctl net.bridge.bridge-nf-call-iptables

# if we disable such setting, the curl will sucess
sysctl -w net.bridge.bridge-nf-call-iptables=0

# if we enable the bridge-nfs-call-iptables, the curl will fail
# since when we curl the VIP through the bridge_home, the packet will hit iptable DNAT rule we just set
# and will change the destinition address to our pod address
# by default, The request needs to be directed to where the request came from!
sysctl -w net.bridge.bridge-nf-call-iptables=1

# Hairpin mode enables a request leaving a device to be received by the same device
# we’ll want our network namespaces to be able to talk to themselves via our virtual IPs
# we’ll need hairpin mode enabled on each port of the bridge device
sudo brctl hairpin bridge_home veth_dustin on
sudo brctl hairpin bridge_home veth_dustin off

# Bridges can be in promiscuous mode, which will treat all attached ports (veths in our case) 
# as if they all had hairpin mode enabled.
sudo ip link set bridge_home promisc on

# the curl will be sure success :) :) :)
sudo ip netns exec netns_dustin curl 10.100.100.100:8080


# align iptables rules with kube-proxy
sudo iptables \
  --table nat \
  --new DUSTIN-SVC-HTTP

sudo iptables \
  --table nat \
  --append DUSTIN-SVC-HTTP \
  --protocol tcp \
  --match tcp \
  --jump DNAT \
  --to-destination 10.0.0.11:8080

sudo iptables \
  --table nat \
  --delete DUSTIN-SERVICES \
  --destination 10.100.100.100 \
  --protocol tcp \
  --match tcp \
  --dport 8080 \
  --jump DNAT \
  --to-destination 10.0.0.11:8080

sudo iptables \
  --table nat \
  --append DUSTIN-SERVICES \
  --destination 10.100.100.100 \
  --protocol tcp \
  --match tcp \
  --dport 8080 \
  --jump DUSTIN-SVC-HTTP

# the curl will be sure success :) :) :)
sudo ip netns exec netns_dustin curl 10.100.100.100:8080

# let's add VIP endpoint 1 support
sudo iptables \
  --table nat \
  --new DUSTIN-SEP-HTTP1

sudo iptables \
  --table nat \
  --append DUSTIN-SEP-HTTP1 \
  --protocol tcp \
  --match tcp \
  --jump DNAT \
  --to-destination 10.0.0.11:8080

sudo iptables \
  --table nat \
  --delete DUSTIN-SVC-HTTP \
  --protocol tcp \
  --match tcp \
  --jump DNAT \
  --to-destination 10.0.0.11:8080

sudo iptables \
  --table nat \
  --append DUSTIN-SVC-HTTP \
  --jump DUSTIN-SEP-HTTP1

# the curl will be sure success :) :) :)
curl 10.100.100.100:8080
sudo ip netns exec netns_dustin curl 10.100.100.100:8080

# let's add VIP endpoint 2 support
sudo iptables \
  --table nat \
  --new DUSTIN-SEP-HTTP2

sudo iptables \
  --table nat \
  --append DUSTIN-SEP-HTTP2 \
  --protocol tcp \
  --match tcp \
  --jump DNAT \
  --to-destination 10.0.0.21:8080

# insert to number 1
# the probability is based on the number of remaining backends to choose from
sudo iptables \
  --table nat \
  --insert DUSTIN-SVC-HTTP 1 \
  --match statistic \
  --mode random \
  --probability 0.5 \
  --jump DUSTIN-SEP-HTTP2

# the curl will be loadbalanced :) :) :)
curl 10.100.100.100:8080
sudo ip netns exec netns_dustin curl 10.100.100.100:8080

# cleanup
sudo iptables -t nat -F
for chain in DUSTIN-SEP-HTTP1  DUSTIN-SEP-HTTP2 DUSTIN-SVC-HTTP DUSTIN-SERVICES; do sudo iptables -t nat -X $chain || true; done


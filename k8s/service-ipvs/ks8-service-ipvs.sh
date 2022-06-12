#!/bin/bash
# Demo the kube-proxy ipvs-mode

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



## emulate VIP 10.100.100.100 (align to ClusterIP in k8s)
sudo ipvsadm \
  --add-service \
  --tcp-service 10.100.100.100:8080 \
  --scheduler rr

# give VIP one endpoint
sudo ipvsadm \
  --add-server \
  --tcp-service 10.100.100.100:8080 \
  --real-server 10.0.0.11:8080 \
  --masquerading
# masquerading vs nat masq ???

curl 10.100.100.100:8080
# FAILED
sudo ip netns exec netns_leah curl -m1 -s -I 10.100.100.100:8080 >/dev/null || echo "FAILED"
# FAILED
sudo ip netns exec netns_dustin curl -m1 -s -I 10.100.100.100:8080 >/dev/null || echo "FAILED"

## to make the connection from netns to host
sudo ip link add dev dustin-ipvs0 type dummy # dummy device usage
sudo ip addr add 10.100.100.100/32 dev dustin-ipvs0
sudo modprobe br_netfilter
sudo sysctl  net.bridge.bridge-nf-call-iptables
sudo sysctl --write net.bridge.bridge-nf-call-iptables=1
# SUCCESS
# request from one device to another device work
sudo ip netns exec netns_leah curl -m1 -s -I 10.100.100.100:8080 >/dev/null || echo "FAILED"
# FAILED
# request from one device to itself still not work 
sudo ip netns exec netns_dustin curl -m1 -s -I 10.100.100.100:8080 >/dev/null || echo "FAILED"

# enable hairpin mode for bridge_home
sudo ip link set bridge_home promisc on
# FAILED
# request from one device to itself still not work 
sudo ip netns exec netns_dustin curl -m1 -s -I 10.100.100.100:8080 >/dev/null || echo "FAILED"

# hairpin mode in ipvs won't work if net.ipv4.vs.conntrack=0
sysctl net.ipv4.vs.conntrack
sysctl -w  net.ipv4.vs.conntrack=1

# sudo sysctl -w net.bridge.bridge-nf-call-iptables=0
# sudo ip l set bridge_home promisc off
# sudo sysctl -w  net.ipv4.vs.conntrack=0
# sudo iptables --table nat --delete POSTROUTING 1

# sudo sysctl -w net.bridge.bridge-nf-call-iptables=1
# sudo ip l set bridge_home promisc on
# sudo iptables --table nat --append POSTROUTING --source 10.0.0.0/24 --jump MASQUERADE
# sudo sysctl -w  net.ipv4.vs.conntrack=1

# SUCCESS :) :) :)
# to make this work, 2 things have to be made sure
# 1. sudo iptables --table nat --append POSTROUTING --source 10.0.0.0/24 --jump MASQUERADE
#    sudo iptables --table nat --delete POSTROUTING 1
# 2. sysctl -w  net.ipv4.vs.conntrack=1
# somethings that are not necessary
# 1. sudo sysctl -w net.bridge.bridge-nf-call-iptables=1
# 2. sudo ip l set bridge_home promisc on


sudo ip netns exec netns_dustin curl -m1 -s -I 10.100.100.100:8080 >/dev/null || echo "FAILED"


# SUCCESS :) :) :)
# to make this work, one of two things have to be made sure
# 1. sudo sysctl -w net.bridge.bridge-nf-call-iptables=1
#  or 
# 1. sudo iptables --table nat --append POSTROUTING --source 10.0.0.0/24 --jump MASQUERADE
sudo ip netns exec netns_leah curl -m1 -s -I 10.100.100.100:8080 >/dev/null || echo "FAILED"


## refine iptable masq rule part 1
sudo iptables \
  --table nat \
  --delete POSTROUTING \
  --source 10.0.0.0/24 \
  --jump MASQUERADE

# clean net.bridge.bridge-nf-call-iptables
sudo sysctl -w net.bridge.bridge-nf-call-iptables=1

# be presise about POSTROUTING
sudo iptables \
  --table nat \
  --append POSTROUTING \
  --source 10.0.0.11/32 \
  --jump MASQUERADE

# SUCCESS :)
# but this specific iptable rule come with a disadvantage: we have to specify every rule for our endpoint
sudo ip netns exec netns_dustin curl -m1 -s -I 10.100.100.100:8080 >/dev/null || echo "FAILED"


## refine iptable masq rule part 2
sudo iptables \
  --table nat \
  --delete POSTROUTING \
  --source 10.0.0.11/32 \
  --jump MASQUERADE
# create ipset rule
# a hashmap that stores dest ip, dest port and source ip
sudo ipset create DUSTIN-LOOP-BACK hash:ip,port,ip
sudo ipset add DUSTIN-LOOP-BACK 10.0.0.11,tcp:8080,10.0.0.11

sudo iptables \
  --table nat \
  --append POSTROUTING \
  --match set \
  --match-set DUSTIN-LOOP-BACK dst,dst,src \
  --jump MASQUERADE

sudo iptables \
  --table nat \
  --append delete \
  --match set \
  --match-set DUSTIN-LOOP-BACK dst,dst,src \
  --jump MASQUERADE

# SUCCESS :)
# more general way of setting POSTROUTING rule for hairpin connections
sudo ip netns exec netns_dustin curl -m1 -s -I 10.100.100.100:8080 >/dev/null || echo "FAILED"


## add another server endpoint
sudo ipvsadm \
  --add-server \
  --tcp-service 10.100.100.100:8080 \
  --real-server 10.0.0.21:8080 \
  --masquerading
sudo ipset add DUSTIN-LOOP-BACK 10.0.0.21,tcp:8080,10.0.0.21

# now request should be loadbalanced to the backend server
# SUCCESS :)
curl -m1 -s -I 10.100.100.100:8080 >/dev/null || echo "FAILED"

# it's weired that netns_dustin curl always success while netns_leah fail for 50%
# SUCCESS :)
sudo ip netns exec netns_dustin curl -m1 -s -I 10.100.100.100:8080 >/dev/null || echo "FAILED"
# SUCCESS :) or FAILED :(
sudo ip netns exec netns_leah curl -m1 -s -I 10.100.100.100:8080 >/dev/null || echo "FAILED"

# to make sure it always success on both netns, we enable the promisc on bridge_home
sudo ip l set bridge_home promisc on
# SUCCESS :)
sudo ip netns exec netns_dustin curl -m1 -s -I 10.100.100.100:8080 >/dev/null || echo "FAILED"
# SUCCESS :)
sudo ip netns exec netns_leah curl -m1 -s -I 10.100.100.100:8080 >/dev/null || echo "FAILED"


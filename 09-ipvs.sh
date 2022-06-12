#!/bin/sh

# refer: https://dev.to/douglasmakey/how-to-setup-simple-load-balancing-with-ipvs-demo-with-docker-4j1d
# refer: https://dustinspecker.com/posts/ipvs-how-kubernetes-services-direct-traffic-to-pods/
# refer: https://debugged.it/blog/ipvs-the-linux-load-balancer/
# refer: https://zhuanlan.zhihu.com/p/94418251

# rr for round roubin, other options are wrr (weight round roubin), lc (least connections), lblc (Locality-Based Least-Connection)
sudo ipvsadm -A -t 100.100.100.100:80 -s rr

# create two containers
docker run -d -p 8000:8000 --name first -t jwilder/whoami
docker run -d -p 8001:8000 --name second -t jwilder/whoami
export ip1=$(docker inspect -f '{{range .NetworkSettings.Networks}}{{.IPAddress}}{{end}}' first)
export ip2=$(docker inspect -f '{{range .NetworkSettings.Networks}}{{.IPAddress}}{{end}}' second)

# add two containers behind our lb
# -t tcp protocol
# -r real server
# -m masquerading
sudo ipvsadm -a -t 100.100.100.100:80 -r $ip1:8000 -m
sudo ipvsadm -a -t 100.100.100.100:80 -r $ip2:8000 -m

# test our loadbalancing
curl 100.100.100.100



# 


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

sudo iptables --table filter --append FORWARD --in-interface bridge_home --jump ACCEPT
sudo iptables --table filter --append FORWARD --out-interface bridge_home --jump ACCEPT

sudo iptables --table nat --append POSTROUTING --source 10.0.0.0/24 --jump MASQUERADE

sudo ip netns exec netns_dustin python3 -m http.server 8080
sudo ip netns exec netns_leah python3 -m http.server 8080

# add service
sudo ipvsadm \
  --add-service \
  --tcp-service 10.100.100.100:8080 \
  --scheduler rr

# add realserver
sudo ipvsadm \
  --add-server \
  --tcp-service 10.100.100.100:8080 \
  --real-server 10.0.0.11:8080 \
  --masquerading

# to enable the communication from netns_dustin to host
sudo ip link add dev dustin-ipvs0 type dummy
sudo ip addr add 10.100.100.100/32 dev dustin-ipvs0

# enable the nat 
sudo modprobe br_netfilter
sudo sysctl --write net.bridge.bridge-nf-call-iptables=1

# why netns_leah can curl success ?
# while netns_dustin curl fail ?
sudo ip netns exec netns_leah curl 10.100.100.100:8080
sudo ip netns exec netns_dustin curl 10.100.100.100:8080


# to make netns_dustin curl success, two things had to be done
# enable promisc on bridge iface
sudo ip link set bridge_home promisc on
# enable virtual server conntrack
sudo sysctl --write net.ipv4.vs.conntrack=1
sudo ip netns exec netns_dustin curl 10.100.100.100:8080

sudo iptables \
  --table nat \
  --delete POSTROUTING \
  --source 10.0.0.0/24 \
  --jump MASQUERADE
# after we delete the masq rule, ipvs nat stop working

# insert a precise masq rule for netns_dustin
# now it works
sudo iptables \
  --table nat \
  --append POSTROUTING \
  --source 10.0.0.11/32 \
  --jump MASQUERADE
sudo ip netns exec netns_dustin curl 10.100.100.100:8080

# even we manage it to work, but we come across with the iptable rules
# so this is not a good solution
# we can use ipset to resolve this delimea
sudo iptables \
  --table nat \
  --delete POSTROUTING \
  --source 10.0.0.11/32 \
  --jump MASQUERADE

sudo ipset create DUSTIN-LOOP-BACK hash:ip,port,ip
# This entry matches the behavior when we make a hairpin connection (a request from netns_dustin to 10.100.100.100:8080 is sent back to 10.0.0.11:8080 [netns_dustin])
sudo ipset add DUSTIN-LOOP-BACK 10.0.0.11,tcp:8080,10.0.0.11
sudo iptables \
  --table nat \
  --append POSTROUTING \
  --match set \
  --match-set DUSTIN-LOOP-BACK dst,dst,src \
  --jump MASQUERADE

sudo iptables \
  --table nat \
  --delete POSTROUTING \
  --match set \
  --match-set DUSTIN-LOOP-BACK dst,dst,src \
  --jump MASQUERADE

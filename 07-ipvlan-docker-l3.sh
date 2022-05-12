#!/bin/sh
# simple bridge, no stp, boradcast/multicast and promisc on
# to test the connectivity from the host to guest, enp0s8 has to be hostonly nic
# enp0s9 belong to hostonly network 192.168.56.0/24
# https://www.youtube.com/watch?v=eVfOmy71NK0
docker network rm ipnet || true
docker network create --driver ipvlan --subnet 192.168.15.0/24 --opt mode=ipvlan-l3 --opt parent=enp0s8 ipnet
docker network inspect ipnet
docker run -it --rm --network ipnet --name c1 alpine
docker run -it --rm --network ipnet --name c2 alpine

# there are two ways to establish the connection from vm guest to docker container

# 1. create a dummy device that share the same ipvlan l3 network
# setup a dummy ipnet0 to communicate with the ipvlan device
ip l add l enp0s8 name ipnet0 type mavlan mode l3
ip l set ipnet0 up
ip a add 1.1.1.1/32 dev ipnet0 # give ipnet0 a random ip address, in ipvlan l3 mode, we don't care the ip address of default ns
ip r add 192.168.15.0/24 dev ipnet0

# test the connectivity from default ns to container ns and vice visa
ping -c1 192.168.15.2
docker exec c1 ping -c1 1.1.1.1


# 2. create a route entry in the host to provide the loop back route to vm guest
route print

netsh int ip add address "以太网 2" 192.168.25.10 255.255.255.0
netsh interface ipv4 add route 192.168.15.0 mask 255.255.255.0 192.168.56.101 # note that the 192.168.56.101 is the vnic's ip address
or 
# route add 192.168.15.0 mask 255.255.255.0 192.168.56.101 # note that the 192.168.56.101 is the vnic's ip address
ping -c1 192.168.15.2

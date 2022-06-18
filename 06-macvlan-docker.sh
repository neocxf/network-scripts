#!/bin/sh
# simple bridge, no stp, boradcast/multicast and promisc on
# to test the connectivity from the host to guest, enp0s9 has to be hostonly nic
# enp0s9 belong to hostonly network 192.168.57.0/24
# https://www.youtube.com/watch?v=Gxnnvwlddpo
docker network rm macnet || true
docker network create --driver macvlan --subnet 192.168.57.0/24 --gateway 192.168.57.1 --opt parent=enp0s9 macnet
docker network inspect macnet
docker run -it --rm --network macnet --ip 192.168.57.200 --name c1 alpine
docker run -it --rm --network macnet --ip 192.168.57.210  --name c2 alpine

# set the promisc on
ip -d l set enp0s9 promisc on

# from host to vm docker 
ping -n 1 192.168.57.200
ping -n 1 192.168.57.210

# test from c1 to c2 and vice visa
docker exec c1 ping -c1 192.168.57.210
docker exec c2 ping -c1 192.168.57.210

# test from c1 to host
# to enable the ping from container to host, we must either stop the host firewall or add a icmp rule for our net 192.168.57.0/24
docker exec c1 ping -c1 192.168.57.1
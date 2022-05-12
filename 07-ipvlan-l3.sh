#!/bin/sh
# with ipvlan l2, promisic is not required
# to test the connectivity from the host to guest, enp0s8 has to be hostonly nic
# enp0s8 belong to hostonly network 192.168.56.0/24
# https://www.youtube.com/watch?v=vhjwL6mpM60
docker network rm ipnet || true
docker network create --driver ipvlan --subnet 192.168.56.0/24 --gateway 192.168.56.1 --opt mode=ipvlan-l2 --opt parent=enp0s8 ipnet
docker network inspect ipnet
docker run -it --rm --network ipnet --name c1 alpine
docker run -it --rm --network ipnet --name c2 alpine

# test the connectivity from default ns to container ns and vice visa
ping -c1 192.168.56.2
docker exec c1 ping -c1 192.168.56.1

# test the connetivity from container c1 to container c2 and vice visa
docker exec c1 ping -c1 192.168.56.3
docker exec c2 ping -c1 192.168.56.2
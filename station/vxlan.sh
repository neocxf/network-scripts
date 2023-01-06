#!/bin/bash

# vm1 192.168.65.200( IP=$(ip route get 4.2.2.2 | awk '{print $7; exit}') )
export VM1_IP=$(ip route get 4.2.2.2 | awk '{print $7; exit}')
export VM1_IFACE=$(ip route get 4.2.2.2 | awk '{print $5; exit}')

# create the docker network hanet
docker network create --subnet 10.10.0.0/16 --opt com.docker.network.bridge.name=hanet hanet

# setup the vxlan device
ip l add vxlan1 type vxlan id 1 dev $VM1_IFACE remote $VM2_IP dstport 8472
ip l set vxlan1 master hanet
ip l set vxlan1 up

sudo tee /etc/netplan/101-vxlan.yaml << __EOF__
network:
  version: 2
#   renderer: NetworkManager

  tunnels:
    vxlan-1:
      mode: vxlan
      id: 1
      local: $VM1_IP
      remote: $VM2_IP
      port: 8472
      link: hanet
__EOF__

# setup the container with the given net and ip address
docker run -it --rm --net hanet  --ip 10.10.0.2 --name hatest1 hub.fastonetech.com/tools/devcontainers/go:0-1-bullseye bash


# vm2 192.168.65.100
export VM2_IP=$(ip route get 4.2.2.2 | awk '{print $7; exit}')
export VM2_IFACE=$(ip route get 4.2.2.2 | awk '{print $5; exit}')

# create the docker network hanet
docker network create --subnet 10.10.0.0/16 --opt com.docker.network.bridge.name=hanet hanet

# setup the vxlan device
ip l add vxlan2 type vxlan id 1 dev $VM2_IFACE remote $VM1_IP dstport 8472
ip l set vxlan2 master hanet
ip l set vxlan2 up

sudo tee /etc/netplan/101-vxlan.yaml << __EOF__
network:
  version: 2
#   renderer: NetworkManager

  tunnels:
    vxlan-1:
      mode: vxlan
      id: 1
      local: $VM2_IP
      remote: $VM1_IP
      port: 8472
      link: hanet
__EOF__

# setup the container with the given net and ip address
docker run -it --rm --net hanet --ip 10.10.0.3 --name hatest1 hub.fastonetech.com/tools/devcontainers/go:0-1-bullseye bash

# test the connectivity from hatest1 to hatest2
ping -c1 10.10.0.3

# test the connectivity from hatest2 to hatest1
ping -c1 10.10.0.2


# capture the traffic
sudo tcpdump -i any 'port 8472' -w vxlan-ping.pcap -nn
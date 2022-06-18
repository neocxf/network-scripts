#!/bin/sh
# https://ilearnedhowto.wordpress.com/2017/02/16/how-to-create-overlay-networks-using-linux-bridges-and-vxlans/
############################### common section start #####################################

INET_DEV=$(ip r get 4.2.2.2 | awk '{ print $(NR+4) }')
# vxlan10 across nfs-server and nfs-client
ip link add vxlan10 type vxlan id 10 group 239.1.1.1 dstport 0 dev $INET_DEV
ip link add br-vxlan10 type bridge
ip link set vxlan10 master br-vxlan10
ip link set vxlan10 up
ip link set br-vxlan10 up

# vxlan20 across nfs-server and nfs-client
ip link add vxlan20 type vxlan id 20 group 239.1.1.1 dstport 0 dev $INET_DEV
ip link add br-vxlan20 type bridge
ip link set vxlan20 master br-vxlan20
ip link set vxlan20 up
ip link set br-vxlan20 up

############################### common section end  #####################################

#############################################################################################
################################### lxc way #################################################
#############################################################################################

############################### nfs-server start #####################################
lxc profile create vxlan10
lxc network attach-profile br-vxlan10 vxlan10
lxc launch images:alpine/edge lhs1 -p vxlan10 -s default
sleep 10 # to wait for the container to be up and ready
lxc exec lhs1 ip addr add 10.100.1.1/24 dev eth0

lxc profile create vxlan20
lxc network attach-profile br-vxlan20 vxlan20
lxc launch images:alpine/edge lhs2 -p vxlan20 -s default
sleep 10 # to wait for the container to be up and ready
lxc exec lhs2 ip addr add 10.100.2.1/24 dev eth0

############################### nfs-server end  #####################################

############################### nfs-client start #####################################

lxc profile create vxlan10
lxc network attach-profile br-vxlan10 vxlan10
lxc launch images:alpine/edge rhs1 -p vxlan10 -s default
sleep 10 # to wait for the container to be up and ready
lxc exec rhs1 ip addr add 10.100.1.2/24 dev eth0

lxc profile create vxlan20
lxc network attach-profile br-vxlan20 vxlan20
lxc launch images:alpine/edge lhs2 -p vxlan20 -s default
sleep 10 # to wait for the container to be up and ready
lxc exec lhs2 ip addr add 10.100.2.2/24 dev eth0

############################### nfs-client end  #####################################

#############################################################################################
############################### non-lxc way #################################################
#############################################################################################

############################### nfs-server start #####################################
ip link add eth10 type veth peer name eth10p
ip link set eth10p master br-vxlan10
ip link set eth10 up
ip link set eth10p up

ip link add eth20 type veth peer name eth20p
ip link set eth20p master br-vxlan20
ip link set eth20 up
ip link set eth20p up

ip addr add 10.200.1.1/24 dev eth10
ip addr add 10.200.2.1/24 dev eth20

ping 10.200.2.1 -c 2 -I eth10 # will not work
############################### nfs-server end  #####################################

############################### nfs-client start #####################################
ip link add eth10 type veth peer name eth10p
ip link set eth10p master br-vxlan10
ip link set eth10 up
ip link set eth10p up

ip link add eth20 type veth peer name eth20p
ip link set eth20p master br-vxlan20
ip link set eth20 up
ip link set eth20p up

ip addr add 10.200.1.2/24 dev eth10
ip addr add 10.200.2.2/24 dev eth20

ping 10.200.2.2 -c 2 -I eth10 # will not work
ping 10.200.1.1 -c 2 -I eth10 # will work using vxlan multicast
ping 10.200.2.1 -c 2 -I eth20 # will work using vxlan multicast

#  from the host side, all other side's ip is pingable
ping 10.200.1.1 -c 1
ping 10.200.2.1 -c 1

############################### nfs-client end  #####################################

# test the connectivity
lxc exec lhs1 -- nc -l -p 9999
lxc exec lhs1 -- nc -zv 10.100.1.1 999

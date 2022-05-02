#!/bin/sh
# refer:
# https://www.sobyte.net/post/2022-01/linux-virtual-network-interfaces/
# https://jiuyashuijing.com/ipip-tunnel-and-its-implementation/
# https://github.com/marywangran/simpletun

###############################################################
# remote: 192.168.56.4
# create a tun device named tap1
ip tuntap add dev tap1 mod tap
# openvpn --mktap --dev tap1
ip link set tap1 up
ip addr add 10.20.0.1/24 dev tap1
# if the other end's network doesn't belong this this tun network, we need add the route manually
ip route add 10.30.0.0/24 dev tap1

# create the tunnel server
./simpletun -i tap1 -s -a

sudo apt install tshark
sudo tshark -i tap1

###############################################################
# local: 192.168.56.3
ip tuntap add dev tap1 mod tap
# openvpn --mktap --dev tap1
ip link set tap1 up
ip addr add 10.30.0.1/24 dev tap1
# if the other end's network doesn't belong this this tun network, we need add the route manually
ip route add 10.20.0.0/24 dev tap1

# connect to the tunnel server
./simpletun -i tap1 -c 192.168.56.4 -a

ping -c1 10.20.0.2

# use scapy to emulate the packet of one bridge with two taps
# https://stackoverflow.com/questions/71603157/two-tap-device-cant-communicate-over-bridge

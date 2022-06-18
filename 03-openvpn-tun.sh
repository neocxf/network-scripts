#!/bin/sh
# refer:
# https://www.sobyte.net/post/2022-01/linux-virtual-network-interfaces/
# https://jiuyashuijing.com/ipip-tunnel-and-its-implementation/
# https://github.com/marywangran/simpletun
# https://backreference.org/2010/03/26/tuntap-interface-tutorial/

###############################################################
# remote: 192.168.56.4
# create a tun device named tun1
ip tuntap add dev tun1 mod tun
# openvpn --mktun --dev tun1
ip link set tun1 up
ip addr add 10.20.0.1/24 dev tun1
# if the other end's network doesn't belong this this tun network, we need add the route manually
ip route add 10.30.0.0/24 dev tun1

# create the tunnel server
./simpletun -i tun1 -s

sudo apt install tshark
sudo tshark -i tun1

###############################################################
# local: 192.168.56.3
ip tuntap add dev tun1 mod tun
# openvpn --mktun --dev tun1
ip link set tun1 up
ip addr add 10.30.0.1/24 dev tun1
# if the other end's network doesn't belong this this tun network, we need add the route manually
ip route add 10.20.0.0/24 dev tun1

# connect to the tunnel server
./simpletun -i tun1 -c 192.168.56.4

ping -c1 10.20.0.2

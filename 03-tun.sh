#!/bin/sh
# refer:
# https://www.sobyte.net/post/2022-01/linux-virtual-network-interfaces/
# https://jiuyashuijing.com/ipip-tunnel-and-its-implementation/
# https://github.com/marywangran/simpletun

# show the tun kernal mod
modinfo tun

############################ machine 1 (192.168.56.4 ) start #######################################
ip tunnel add mytun mode ipip remote 192.168.56.3 local 192.168.56.4
ip a add 10.42.1.1/24 dev mytun
ip l set mytun up
ip r add 10.42.2.0/24 dev mytun
############################ machine 1 (192.168.56.4 ) end ##########################################

############################ machine 1 (192.168.56.3 ) start ########################################

ip tunnel add mytun mode ipip remote 192.168.56.4 local 192.168.56.3
ip a add 10.42.2.1/24 dev mytun
ip l set mytun up
ip r add 10.42.1.0/24 dev mytun

############################ machine 1 (192.168.56.3 ) end ###########################################

############################ machine 1 (192.168.56.4 ) test start ####################################
tcpdump -i enp0s8 -w pptun.pcap
ping -c1 10.42.2.1
############################ machine 1 (192.168.56.4 ) test end ######################################


############################ machine 1 (192.168.56.4 ) start #######################################
ip netns add n1
ip netns add n2
ip l add br1 type bridge 
ip a add 10.52.1.1/24 dev br1
ip l set br1 up

# setup veth1
ip l add veth1h type veth peer veth1c
ip l set veth1c netns n1
ip netns exec n1 ip l set lo up
ip netns exec n1 ip a add 10.52.1.2/24 dev veth1c
ip netns exec n1 ip l set veth1c up

ip l set veth1h master br1
ip l set veth1h up

ip netns exec n1 ip r add default via 10.52.1.1


# setup veth2
ip l add veth2h type veth peer veth2c
ip l set veth2c netns n2
ip netns exec n2 ip l set lo up
ip netns exec n2 ip a add 10.52.1.3/24 dev veth2c
ip netns exec n2 ip l set veth2c up

ip l set veth2h master br1
ip l set veth2h up

ip netns exec n2 ip r add default via 10.52.1.1

# setup iptables rule to enable internet access
iptables -t nat -A POSTROUTING ! -o br1 -s 10.52.1.0/24 -j MASQUERADE

ip netns exec n1 ping -c1 4.2.2.2

ip tun add tun0 mode gre remote 192.168.56.4 local 192.168.56.3
# should use a reserved address for the specific tunneling, otherwise will collapse with the other host in the network
# not needed when gre mode???
# ip a add 10.52.1.254 peer 10.52.2.254 dev tun0
ip l set tun0 up
ip r add 10.52.2.0/24 dev tun0
############################ machine 1 (192.168.56.4 ) end ##########################################


############################ machine 1 (192.168.56.3 ) start #######################################
ip netns add n1
ip netns add n2
ip l add br1 type bridge 
ip a add 10.52.2.1/24 dev br1
ip l set br1 up

# setup veth1
ip l add veth1h type veth peer veth1c
ip l set veth1c netns n1
ip netns exec n1 ip l set lo up
ip netns exec n1 ip a add 10.52.2.2/24 dev veth1c
ip netns exec n1 ip l set veth1c up

ip l set veth1h master br1
ip l set veth1h up

ip netns exec n1 ip r add default via 10.52.2.1

# setup veth2
ip l add veth2h type veth peer veth2c
ip l set veth2c netns n2
ip netns exec n2 ip l set lo up
ip netns exec n2 ip a add 10.52.2.3/24 dev veth2c
ip netns exec n2 ip l set veth2c up

ip l set veth2h master br1
ip l set veth2h up

ip netns exec n2 ip r add default via 10.52.2.1

# setup iptables rule to enable internet access
iptables -t nat -A POSTROUTING ! -o br1 -s 10.52.2.0/24 -j MASQUERADE

ip netns exec n1 ping -c1 4.2.2.2

ip tun add tun0 mode gre remote 192.168.56.4 local 192.168.56.3
# not needed when gre mode???
# ip a add 10.52.2.254 peer 10.52.1.254 dev tun0
ip l set tun0 up
ip r add 10.52.1.0/24 dev tun0
############################ machine 1 (192.168.56.3 ) end ##########################################
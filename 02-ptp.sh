#!/bin/bash


function setup_ptp() {
    ip netns add $NS
    ip link add $PTP_VETH type veth peer name $PTP_CETH
    ip a add $PTP_GW/32 dev $PTP_VETH
    ip l set $PTP_VETH up
    ip r add $PTP_CIP dev $PTP_VETH scope host

    ip link set $PTP_CETH netns $NS
    ip netns exec $NS ip link set $PTP_CETH up
    ip netns exec $NS ip a add $PTP_CIP/24 dev $PTP_CETH

    ip netns exec $NS ip a

    ip netns exec $NS ip r

    ip netns exec $NS ip r del $PTP_NET/24 dev $PTP_CETH
    ip netns exec $NS ip r add $PTP_GW dev $PTP_CETH 
    ip netns exec $NS ip r add $PTP_NET/24 via $PTP_GW dev $PTP_CETH
    ip netns exec $NS ip r add default via $PTP_GW dev $PTP_CETH

    # test from container to host

    ip netns exec $NS ping -c 2 $PTP_GW

    # test from host to container
    ping -c 2 $PTP_CIP

    sysctl -a | grep "net.ipv4.ip_forward"
    sysctl -w net.ipv4.ip_forward=1

    ip netns exec $NS sysctl -a | grep "net.ipv4.ip_forward"
    ip netns exec $NS sysctl -w net.ipv4.ip_forward=1

    echo -e "\n before modify the iptables nat table ..."
    iptables -t nat -nvL

    # turn on POSTROUTING when access the internet
    iptables -t nat -N CNI-$NS
    iptables -t nat -A POSTROUTING -s $PTP_CIP/32 -m comment --comment "name: \"$NS\" id: \"$NS\"" -j CNI-$NS
    iptables -t nat -A CNI-$NS -d $PTP_NET/24 -m comment --comment "name: \"$NS\" id: \"cnitool-$NS-accept\"" -j ACCEPT
    iptables -t nat -A CNI-$NS ! -d 224.0.0.0/4 -m comment --comment "name: \"$NS\" id: \"cnitool-$NS-masquerade\"" -j MASQUERADE
    
    echo -e "\n after modify the iptables nat table ..."
    iptables -t nat -nvL

}

. env.sh

echo -e "\nclean ns [$NS] scene"
iptables -t nat -F POSTROUTING
iptables -t nat -X CNI-$NS || true
ip netns delete $NS || true

export C1IP=$PTP_CIP
export C1NS=$NS

echo -e "\nsetting up ns [ $NS ]"
setup_ptp

export NS=c2
export PTP_CIP=10.10.0.3
export PTP_VETH=veth1
export PTP_CETH=ceth1

export C2IP=$PTP_CIP
export C2NS=$NS

echo -e "\nclean ns [$NS] scene"
iptables -t nat -X CNI-$NS || true
ip netns delete $NS || true
echo -e "\nsetting up ns [ $NS ]"
setup_ptp


echo -e "\nTest root ns to ns $C1NS [$C1IP] connectivity"
ping -c 2 $C1IP
echo -e "\nTest root ns to ns $C2NS [$C2IP] connectivity"
ping -c 2 $C2IP
echo -e "\nTest ns [ $C1NS ] to gw [$PTP_GW] connectivity"
ip netns exec $C1NS ping -c 2 $PTP_GW
echo -e "\nTest ns [ $C2NS ] to gw [$PTP_GW] connectivity"
ip netns exec $C2NS ping -c 2 $PTP_GW
echo -e "\nTest ns [ $C1NS ] to ns $C2NS [$C2IP] connectivity"
ip netns exec $C1NS ping -c 2 $C2IP
echo -e "\nTest ns [ $C2NS ] to ns $C1NS [$C1IP] connectivity"
ip netns exec $C2NS ping -c 2 $C1IP
# https://unix.stackexchange.com/a/612434/142191
echo -e "\nTest internet connectivity for ns [ $C1NS ]"
ip netns exec $C1NS ping -c 2 4.2.2.2
echo -e "\nTest internet connectivity for ns [ $C2NS ]"
ip netns exec $C2NS ping -c 2 4.2.2.2

echo -e "\nThe final iptables nat table looks like: \n\n"
iptables -t nat -nvL
echo -e "\n\n"

echo -e "\nFlush nat table POSTROUTING chain"
iptables -t nat -F POSTROUTING

echo -e "\nFlush and delete nat table CNI-$C1NS chain"
iptables -t nat -F CNI-$C1NS
iptables -t nat -X CNI-$C1NS

echo -e "\nFlush and delete nat table CNI-$C2NS chain"
iptables -t nat -F CNI-$C2NS
iptables -t nat -X CNI-$C2NS

echo -e "\nClean the ns: [ $C1NS, $C2NS ]"
ip netns delete $C1NS 
ip netns delete $C2NS
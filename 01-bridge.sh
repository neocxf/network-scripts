#!/bin/bash

function test_bridge() {
    ip netns add $NS
    ip link add $BRG_VETH type veth peer name $BRG_CETH

    # setup ceth
    ip link set $BRG_CETH netns $NS
    ip netns exec $NS ip l set lo up
    ip netns exec $NS ip l set $BRG_CETH up
    ip netns exec $NS ip a add $BRG_CIP/24 dev $BRG_CETH
    ip netns exec $NS ip a

    # add br0
    # brctl addbr $BRG_NAME
    ip link add $BRG_NAME type bridge
    ip addr add $BRG_GW/24 dev $BRG_NAME
    ip link set $BRG_NAME up

    # setup veth
    ip link set $BRG_VETH master $BRG_NAME
    ip link set $BRG_VETH up

    # add default gw
    # ip route add default via $BRG_GW
    #route add default gw $BRG_GW $BRG_VETH
    ip netns exec $NS ip r add default via $BRG_GW dev $BRG_CETH

    # turn on ip-forwarding on host
    enable_ip_forwarding

    # turn on POSTROUTING when access the internet
    iptables -t nat -A POSTROUTING ! -o $BRG_NAME -s $BRG_NET/24 -j MASQUERADE

    # turn on PREROUTING for external ip to access the $NS service
    echo -e "\n enable the external connectivity from lan port [ $BRG_PORT ] to container [ $BRG_CIP:$BRG_PORT ]"
    iptables -t nat -A PREROUTING -m addrtype --dst-type LOCAL ! -i $BRG_NAME -p tcp -m tcp --dport $BRG_PORT -j DNAT --to-destination $BRG_CIP:$BRG_PORT
    # iptables -t nat -A PREROUTING  -p tcp -m tcp --dport $BRG_PORT -j DNAT --to-destination $BRG_CIP:$BRG_PORT

    # turn on route_localnet to enable the local nc to work
    echo -e "\n enable the local connectivity from port [ $BRG_PORT ] to container [ $BRG_CIP:$BRG_PORT ]"
    enable_local_route
    # with this option setup, port forwarding trick will not work
    iptables -t nat -A OUTPUT -m addrtype --dst-type LOCAL -p tcp -o lo --dport $BRG_PORT -j DNAT --to-destination $BRG_CIP:$BRG_PORT
    
    # enable the localhost access to the given port
    # https://dustinspecker.com/posts/iptables-how-docker-publishes-ports
    iptables -t nat -A POSTROUTING -m addrtype --dst-type LOCAL -p tcp -s 127.0.0.1 -o $BRG_NAME -j MASQUERADE

    # proxy mode: 
    # with this setup, we can omit the upper two nat rule
    # ssh -L 0.0.0.0:$BRG_PORT:$BRG_CIP:$BRG_PORT root@localhost
    # socat tcp-l:$BRG_PORT,fork,reuseaddr tcp:$BRG_CIP:$BRG_PORT

    # check the newly configured iptables
    iptables -t nat -nvL

    # enter the given netns to test
    ip netns exec $NS /bin/bash

    # configure the resolv.conf to access the dns
    # https://dustinspecker.com/posts/how-do-kubernetes-and-docker-create-ip-addresses/#create-a-network-namespace
    mkdir -p /etc/netns/$NS/ && cp /etc/resolv.conf /etc/netns/$NS/
    sed  -i "s/nameserver 127.0.0.53/nameserver 8.8.8.8/" /etc/netns/$NS/resolv.conf

    # test the dns
    ping www.baidu.com

    # check the syscall access point when exec at the given netns
    strace -f ip netns exec $NS sleep 1 2>&1|egrep '/etc/|clone|mount|unshare'|egrep -vw '/etc/ld.so|access'
}

function emulate_docker_proxy_mode() {
    ssh-keygen
    cat ~/.ssh/id_rsa.pub >> ~/.ssh/authorized_keys
    # emulate the docker-proxy (have to exclude the route_localnet)
    # https://windsock.io/the-docker-proxy
    ip netns exec $NS `which sshd` -p $BRG_PORT
    ssh -L 0.0.0.0:$BRG_PORT:$BRG_CIP:$BRG_PORT root@localhost
    # or socat
    # socat tcp-l:$BRG_PORT,fork,reuseaddr tcp:$BRG_CIP:$BRG_PORT
    echo -e "\n test from localhost for prerouting rule"
    nc -zv localhost 3333
}

function docker_proxy_mode() {
    # https://windsock.io/the-docker-proxy
    docker-proxy -proto tcp -host-ip 0.0.0.0 -host-port $BRG_PORT -container-ip $BRG_CIP -container-port $BRG_PORT
}


function enable_ip_forwarding() {
    echo -e "\n enable kernel ip_forwarding ability"
    sysctl -a | grep "net.ipv4.conf.all.forwarding"

    sysctl -w net.ipv4.conf.all.forwarding=1
    iptables -P FORWARD ACCEPT
}

function enable_local_route() {
    sysctl -a | grep "route_localnet"

    echo -e "\n enable kernel route_localnet ability"
    sysctl -w net.ipv4.conf.all.route_localnet=1

}

function enable_log() {
    alias ipl="iptables -nvL --line-numbers"
    iptables-save > iptables-default.log
    iptables -F
    # log the http port
    iptables -I INPUT 1 -p tcp --dport http -j LOG

    tail -fn100 /var/log/kern.log

    # debug the table
    iptables -t mangle -A PREROUTING -p tcp --dport $BRG_PORT  -j LOG --log-level warning --log-prefix "[_REQUEST_COMING_FROM_CLIENT_] "
    iptables -t nat -A POSTROUTING -p tcp  -j LOG --log-level warning --log-prefix "[_REQUEST_BEING_FORWARDED_] "
}

function load_docker_iptables() {
    iptables-save -t nat > origin-iptables.txt
    iptables-restore < docker-iptables.txt
    # verifying the new iptables
    iptables -t nat -nvL
    iptables -t nat -F
    iptables-restore < origin-iptables.txt
}

function show_avail_match_options() {
    # show the available icmp type
    iptables -p icmp --help

    # show the available addrtype
    iptables -m addrtype --help
}

. env.sh

test_bridge

# test connectivity
ip netns exec $NS `which sshd` -p $BRG_PORT &

iptables -t nat -I PREROUTING -m tcp -p tcp --dport 6000 -m comment --comment "redirect pkts to virtual machine" -j DNAT --to-destination 192.168.1.10:22   
iptables -t nat -I POSTROUTING -m comment --comment "NAT the src ip" -d 192.168.1.10 -o eth1 -j MASQUERADE




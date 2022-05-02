# network-scripts

## Kinds of network mode

### DNS resolve

[Why does /etc/resolv.conf point at 127.0.0.53?](https://unix.stackexchange.com/a/612434/142191)
[Resolving Kubernetes Services from Host when using kind](https://dustinspecker.com/posts/resolving-kubernetes-services-from-host-when-using-kind/)

### TUN/TAP mode

![openvpn](https://hechao.li/img/tun-use-case.png)

### Bridge mode

[How Do Kubernetes and Docker Create IP Addresses?!](https://dustinspecker.com/posts/how-do-kubernetes-and-docker-create-ip-addresses/)
[iptables: how docker publishes ports](https://dustinspecker.com/posts/iptables-how-docker-publishes-ports/)
[Linux NetFilter, IP Tables and Conntrack Diagrams](https://gist.github.com/neocxf/a6682c7b521e5915a6ae0ba0c883cf5d)

### PTP mode

[ptp source impl](https://github.com/containernetworking/plugins/blob/main/plugins/main/ptp/ptp.go)
[ptp plugin](https://www.cni.dev/plugins/current/main/ptp/)

### IPVS mode

[IPVS: How Kubernetes Services Direct Traffic to Pods](https://dustinspecker.com/posts/ipvs-how-kubernetes-services-direct-traffic-to-pods/)

### IPVLAN mode

[ IPVLAN Driver HOWTO](https://www.kernel.org/doc/Documentation/networking/ipvlan.txt)
[ IPVLAN plugin](https://www.cni.dev/plugins/current/main/ipvlan/)

### MACVLAN mode

[MACVLAN plugin](https://www.cni.dev/plugins/current/main/macvlan/)
[MACVLAN notes](https://backreference.org/2014/03/20/some-notes-on-macvlanmacvtap/)

## virtualbox network type

[overview of virtualbox network type](https://forums.virtualbox.org/viewtopic.php?f=35&t=96608)
[virtualbox networking setting guide](https://www.nakivo.com/blog/virtualbox-network-setting-guide/)

## Big pictures or overview

[Linux NetFilter, IP Tables and Conntrack Diagrams](https://gist.github.com/neocxf/a6682c7b521e5915a6ae0ba0c883cf5d)
![vxlan explained](https://hechao.li/img/vxlan-unicast.png)

## refer

[container networking is simple](https://iximiuz.com/en/posts/container-networking-is-simple/)
[nftables packet flow details](https://thermalcircle.de/doku.php?id=blog:linux:nftables_packet_flow_netfilter_hooks_detail)
[nftables ipsec packet flow](https://thermalcircle.de/doku.php?id=blog:linux:nftables_ipsec_packet_flow)

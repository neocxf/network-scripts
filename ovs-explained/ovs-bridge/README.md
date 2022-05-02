# test ovs bridge

## basic commands

```bash
ovs-vsctl add-br mybridge
ovs-vsctl show mybridge

# add eth0(internet) to mybridge
ovs-vsctl add-port mybridge eth0

# remove the ip addr from enp0s3
ifconfig enp0s3 0

# get an ip addr from DHCP server
dhclient mybridge

ip tuntap add vport1 mode tap
ip tuntap add vport2 mode tap
ip link set vport1 up
ip link set vport2 up

ovs-vsctl add-port mybridge vport1 -- add-port mybridge vport2

```

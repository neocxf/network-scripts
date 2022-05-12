# test ovs bridge

## add a ovs bridge named mybridge

```bash
ovs-vsctl add-br mybridge
ovs-vsctl show mybridge

# add eth0(internet) to mybridge
ovs-vsctl add-port mybridge eth0

# remove the ip addr from enp0s3
ifconfig enp0s3 0
# or
ip addr flush dev enp0s3

# get an ip addr from DHCP server
dhclient -v mybridge

ip tuntap add vport1 mode tap
ip tuntap add vport2 mode tap
ip link set vport1 up
ip link set vport2 up

ovs-vsctl add-port mybridge vport1 -- add-port mybridge vport2

# use the vport1 and vport2 as the bridge adapter of mininet1 and mininet2

# check the mac address of mybridge
ovs-appctl fdb/show mybridge

# show the openflow port
ovs-ofctl show mybridge

# by default ovs-bridge will act as layer2 bridge with mac address learning
ovs-ofctl dump-flows mybridge
#  cookie=0x0, duration=15867.702s, table=0, n_packets=527437, n_bytes=630847024, priority=0 actions=NORMAL

# show all the bridge 
ovs-vsctl list bridge

# show all the port
ovs-vsctl list port

# show all the interface
ovs-vsctl list interface


```

## make mybridge perisisted from reboot
```bash
cp /etc/netplan/01-network-manager-all.yaml /etc/netplan/01-network-manager-all.yaml.bak
cat > /etc/netplan/01-network-manager-all.yaml << '__EOF__'
network:
  version: 2
  renderer: NetworkManager
  
  ethernets:
    enp0s3:
      dhcp4: no
      dhcp6: no

  bridges:
    mybridge:
      dhcp4: yes
      dhcp6: no
      interfaces: ["enp0s3"]
      parameters:
        stp: false
        forward-delay: 0
__EOF__

netplan apply
```

## revert back to normal mode

```bash
ovs-vsctl del-port mybridge enp0s3
ovs-vsctl del-port mybridge vport1
ovs-vsctl del-port mybridge vport2

cat > /etc/netplan/01-network-manager-all.yaml << '__EOF__'
network:
  version: 2
  renderer: NetworkManager
__EOF__
netplan apply
```
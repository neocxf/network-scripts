# test with virt-vagrant provider

## test customized network

```bash
cat > /tmp/macvtap-net.xml << __EOF__
<network>
  <name>macvtap-net</name>
  <forward mode="bridge">
    <interface dev="enp0s3"/>
  </forward>
</network>
__EOF__
virsh net-define /tmp/macvtap-net.xml
virsh net-autostart macvtap-net
virsh net-start macvtap-net


virt-install --name=cirros --ram=256 --vcpus=1 \
--disk path=/home/node1/network-scripts/images/cirros-0.5.2-x86_64-disk.img,format=qcow2 \
--import --network network:macvtap-net,model=virtio --vnc

# show the vnc address
virsh vncdisplay cirros
# use virt-viewer to view cirros
virt-viewer --connect qemu:///system --wait cirros
# use console to login to the console
virsh console cirros  --force

virsh dominfo cirros

# stop the my-network
virsh destroy macvtap-net
# delete it completly
virsh net-undefine macvtap-net
```

## using the customized network

```bash
vagrant up
```


# Refer
1. [virsh cheetsheet](https://computingforgeeks.com/virsh-commands-cheatsheet/)
2. [using kvm libvirt macvtap interfaces](https://blog.scottlowe.org/2016/02/09/using-kvm-libvirt-macvtap-interfaces/)
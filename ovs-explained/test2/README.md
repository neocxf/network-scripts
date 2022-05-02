# test with virt-vagrant provider

## test customized network

```bash
cat > /tmp/my-network.xml << __EOF__
<network>
  <name>my-network</name>
  <bridge name='my-bridge' stp='on' delay='0'/>
  <ip address='10.100.0.1' netmask='255.255.255.0'>
    <dhcp>
      <range start='10.100.0.2' end='10.100.0.254'/>
    </dhcp>
  </ip>
</network>
__EOF__
virsh net-define /tmp/my-network.xml
virsh net-start my-network

# stop the my-network
virsh destroy my-network
# delete it completly
virsh net-undefine my-network
```

## using the customized network

```bash
vagrant up
```

# nfs protocol explained

```shell
# test with nfs v4 mount
strace -t -e network -o trace.log -ff mount -t nfs -o defaults 13.212.141.66:/opt/fastone/softwares /fastone-mnt/10

# test with nfs v3 mount options
strace -t -e network -o trace.log -ff mount -t nfs -o defaults,v3 13.212.141.66:/opt/fastone/softwares /fastone-mnt/10

tcpdump -i enp0s8 port nfs
tcpdump -i enp0s8 'tcp[13] & 2 == 2' -vv

tcpdump 'tcp[tcpflags] & (tcp-syn|tcp-fin) != 0 and not src and dst net localnet'

```

## Refer
[nfs4-single-port](https://peteris.rocks/blog/nfs4-single-port/)
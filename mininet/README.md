# mininet usage

## basic setup

```bash
echo 'mininet\n' | ssh -X mininet@192.168.56.101

sudo xauth merge ~/.Xauthority

# add and delete host names or user names to the list allowed to make connections to the X server
xhost

# clean up any stale resources that created by mininet
sudo mn -c

# introduce a bandwith of 10mbps, latency of 10ms network
sudo mn --link tc,bw=10,delay=10ms

sudo wireshark &

sudo mn --topo=single,4
sudo mn --topo=linear,4
sudo mn --topo=tree,2,2

```

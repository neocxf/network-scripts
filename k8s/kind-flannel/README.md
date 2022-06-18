# containerd

```bash
cd busybox
mkdir rootfs
docker export $(docker create busybox) | tar -C rootfs -xvf -

```

## supervision tech

```bash
http://smarden.org/runit/

```

## network details

> Flannel is responsible for providing a layer 3 IPv4 network between multiple nodes in a cluster. Flannel does not control how containers are networked to the host, only how the traffic is transported between hosts

## install flanneld

```bash
flanneld=$(curl -s https://api.github.com/repos/flannel-io/flannel/releases/latest | jq -r '.assets[] | select (.name == "flanneld-amd64") | .browser_download_url')
curl -v $flanneld -o /usr/local/bin/flanneld
chmod a+x /usr/local/bin/flanneld


# crictl-v1.24.2-linux-amd64.tar.gz
# https://jqplay.org/jq
critools_ver=$(curl -s https://api.github.com/repos/kubernetes-sigs/cri-tools/releases/latest | jq -r '.tag_name')
critools_tgz=$(curl -s https://api.github.com/repos/kubernetes-sigs/cri-tools/releases/latest | jq -r '.assets[] | select (.name | match("^crictl-.*-linux-amd64\\.tar\\.gz$"; "g") ) | .browser_download_url')

# works
curl -fsSL $critools_tgz | tar xzv -C /opt/cni/bin
# works
wget -qO - $critools_tgz | tar xzvf - -C /opt/cni/bin
# works
( cd /opt/cni/bin && wget -O - $critools_tgz | tar xzvf - )

# works
wget -P /tmp $critools_tgz
tar xzvf /tmp/crictl-$critools_ver-linux-amd64.tar.gz -C /opt/cni/bin

cniplugins_ver=$(curl -s https://api.github.com/repos/containernetworking/plugins/releases/latest | jq -r '.tag_name')
cniplugins_tgz=$(curl -s https://api.github.com/repos/containernetworking/plugins/releases/latest | jq -r '.assets[] | select (.name | match("^cni-plugins-linux-amd64-.*\\.tgz$"; "g") ) | .browser_download_url')

( cd /opt/cni/bin && wget -O - $cniplugins_tgz | tar xzf - )
wget -qO - $cniplugins_tgz | tar xvzf -C /opt/cni/bin

```
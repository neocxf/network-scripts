#!/bin/bash
# refer: https://medium.com/swlh/customise-your-kind-clusters-networking-layer-1249e7916100
# refer: https://www.buzzwrd.me/index.php/2022/02/16/calico-to-flannel-changing-kubernetes-cni-plugin/
# setup flannel
kubectl apply -f https://raw.githubusercontent.com/coreos/flannel/master/Documentation/kube-flannel.yml

kubectl create deployment nginx --image=nginx --replicas=2
# expose the service
kubectl expose deploy nginx --port=80 --target-port=80

ps -U0 -o 'tty,pid,comm' | grep -i dockerd


# awk command
# https://www.thegeekstuff.com/2010/01/8-powerful-awk-built-in-variables-fs-ofs-rs-ors-nr-nf-filename-fnr/

nsenter -t $(ps -U0 -o 'tty,pid,comm' | grep -i nginx | awk '{ print $2 }') -n ip a

tshark -i any -lnV host 172.18.0.3
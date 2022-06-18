#!/bin/bash
# refer: https://alexbrand.dev/post/creating-a-kind-cluster-with-calico-networking/
# refer: https://medium.com/flant-com/calico-for-kubernetes-networking-792b41e19d69
# refer: https://www.buzzwrd.me/index.php/2022/02/16/calico-to-flannel-changing-kubernetes-cni-plugin/
# setup calico
kubectl apply -f https://docs.projectcalico.org/manifests/calico.yaml

kubectl create deployment nginx --image=nginx --replicas=2
# expose the service
kubectl expose deploy nginx --port=80 --target-port=80


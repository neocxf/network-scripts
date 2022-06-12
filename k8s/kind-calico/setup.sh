#!/bin/bash
# setup calico
kubectl apply -f https://docs.projectcalico.org/manifests/calico.yaml

kubectl create deployment nginx --image=nginx --replicas=2
# expose the service
kubectl expose deploy nginx --port=80 --target-port=80

ps -U0 -o 'tty,pid,comm' | grep -i dockerd

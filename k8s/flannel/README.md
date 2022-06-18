# k8s bgp dynamic route

## service definition
```yaml
apiVersion: v1
kind: Service
metadata:
  name: app-service
spec:
  clusterIP: 10.100.100.100
  selector:
    component: app
  ports:
    - protocol: TCP
      port: 8080
      targetPort: 8080
```

## boot vm1 and vm2

```bash
multipass launch \
  --cloud-init vm1.yaml \
  --name vm1 \
  --mem 1024M \
  20.04
multipass launch \
  --cloud-init vm2.yaml \
  --name vm2 \
  --mem 1024M \
  20.04
```

## setup env in vm1 and vm2

```bash
# mount current directory to vm1 and vm2
multipass mount `pwd` vm1:~/scripts
multipass mount `pwd` vm2:~/scripts
```

## setup intra-net network

```bash
mutlipass exec vm1 -- sudo bash scripts/setupvm.sh
mutlipass exec vm2 -- sudo bash scripts/setupvm.sh
```


## setup inter-net network by ipip mode

```bash
mutlipass exec vm1 -- sudo bash scripts/ipip.sh
mutlipass exec vm2 -- sudo bash scripts/ipip.sh
```

## setup inter-net network by bgp mode

```bash
mutlipass exec vm1 -- sudo bash scripts/bgp.sh
mutlipass exec vm2 -- sudo bash scripts/bgp.sh
```
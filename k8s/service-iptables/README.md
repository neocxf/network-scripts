# k8s iptables mode

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

## dump the kube-proxy iptables-mode config

```bash
-P PREROUTING ACCEPT
-P INPUT ACCEPT
-P OUTPUT ACCEPT
-P POSTROUTING ACCEPT
-N DUSTIN-SEP-HTTP1
-N DUSTIN-SEP-HTTP2
-N DUSTIN-SERVICES
-N DUSTIN-SVC-HTTP
-A PREROUTING -j DUSTIN-SERVICES
-A OUTPUT -j DUSTIN-SERVICES
-A POSTROUTING -s 10.0.0.0/24 -j MASQUERADE
-A DUSTIN-SEP-HTTP1 -p tcp -m tcp -j DNAT --to-destination 10.0.0.11:8080
-A DUSTIN-SEP-HTTP2 -p tcp -m tcp -j DNAT --to-destination 10.0.0.21:8080
-A DUSTIN-SERVICES -d 10.100.100.100/32 -p tcp -m tcp --dport 8080 -j DUSTIN-SVC-HTTP
-A DUSTIN-SVC-HTTP -m statistic --mode random --probability 0.50000000000 -j DUSTIN-SEP-HTTP2
-A DUSTIN-SVC-HTTP -j DUSTIN-SEP-HTTP1

```
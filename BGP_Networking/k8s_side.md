##install calicoctl
```bash
curl -L https://github.com/projectcalico/calico/releases/download/v3.27.2/calicoctl-linux-amd64 -o calicoctl
chmod +x calicoctl
mv calicoctl /usr/local/bin/
export DATASTORE_TYPE=kubernetes
export DATASTORE_TYPE=kubernetes
```
## create a bgppeer configaration
```bash
vim bgppeer.yaml
apiVersion: projectcalico.org/v3
kind: BGPPeer
metadata:
  name: external-peer-212
spec:
  peerIP: 192.168.20.212
  asNumber: 64512

```
## deploy the configaration
```bash
calicoctl apply -f bgppeer.yaml --allow-version-mismatch
kubectl get bgppeers -o wide
kubectl describe bgppeers
```

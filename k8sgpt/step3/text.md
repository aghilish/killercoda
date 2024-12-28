## install schednex
```bash
helm repo add schednex-ai https://charts.schednex.ai
helm repo update
```{{exec}}

```bash
helm install schednex-scheduler schednex-ai/schednex -n kube-system
```{{exec}}


## create a sample pod to be scheduled by schednex

```bash
kubectl apply -f - << EOF
apiVersion: v1
kind: Pod
metadata:
  name: nginx
spec:
  schedulerName: schednex
  containers:
  - image: nginx
    name: nginx
EOF
```{{exec}}
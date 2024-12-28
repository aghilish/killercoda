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
apiVersion: apps/v1
kind: Deployment
metadata:
  name: nginx-deployment
  labels:
    app: nginx
spec:
  replicas: 3
  selector:
    matchLabels:
      app: nginx
  template:
    metadata:
      labels:
        app: nginx
    spec:
      schedulerName: schednex
      containers:
      - name: nginx
        image: nginx:1.14.2
        ports:
        - containerPort: 80
EOF
```{{exec}}
# k8sgpt

## 1. authenticate with ai backend 

```bash
k8sgpt generate
```{{exec}}


```bash
k8sgpt auth add --backend openai --model gpt-3.5-turbo
```{{exec}}

```bash
k8sgpt auth list
```{{exec}}

```bash
k8sgpt filters list
```{{exec}}

## 2. create a broken pod

```bash
cat <<EOF | kubectl apply -f -
apiVersion: v1
kind: Pod
metadata:
  name: broken-pod
  namespace: default
spec:
  containers:
    - name: broken-pod
      image: nginx:1.a.b.c
      livenessProbe:
        httpGet:
          path: /
          port: 81
        initialDelaySeconds: 3
        periodSeconds: 3
EOF
```{{exec}}

## 3. analyze the issue

```bash
k8sgpt analyze
```{{exec}}
```bash
export AI_BACKEND=openai #. run `k8sgpt auth list` for a complete list of available ai backends
k8sgpt analyse --explain --backend $AI_BACKEND
```{{exec}}

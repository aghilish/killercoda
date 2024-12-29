# k8sgpt

let's start with the CLI and its different commands

```bash
k8sgpt --help
```{{exec}}

## 1. authenticate cli with ai backend 
[! CAUTION] >
> It is recommended to generate a new API key for your chosen AI backend and deactivating or deleting it immediately after completing the lab. This ensures better security.

```bash
k8sgpt generate
```{{exec}}

```bash
k8sgpt auth add --backend openai --model gpt-3.5-turbo
```{{exec}}

```bash
k8sgpt auth list
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

We can narrow down troubleshooting to specific resources by applying filters.
Before proceeding, let's review the supported filters.
Each filter corresponds to an analyzer within the CLI program.

```bash
k8sgpt filters list
```{{exec}}


In the previous step, we created a problematic pod. Let's analyze it first:  

```bash
k8sgpt analyze --filter Pod
```{{exec}}

In order to add to or remove from the active filters we can run `k8sgpt filters add` or `k8sgpt filters remove` commands.

To get AI-driven insights on how to fix the issue, use the `--explain` flag. This sends the error to the AI backend for further analysis:  

```bash
k8sgpt analyze --filter Pod --explain
```{{exec}}  

You can explicitly select the AI backend using the `--backend` flag, which is useful if you are authenticated with multiple backends.

```bash
export AI_BACKEND=openai #. run `k8sgpt auth list` for a complete list of available ai backends
k8sgpt analyse --explain --backend $AI_BACKEND
```{{exec}}

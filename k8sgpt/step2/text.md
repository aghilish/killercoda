
## installing prometheus

```bash
helm repo add prometheus-community https://prometheus-community.github.io/helm-charts
```{{exec}}

```bash
helm repo update
```{{exec}}

```bash
helm upgrade --install prometheus prometheus-community/kube-prometheus-stack --set prometheus.prometheusSpec.serviceMonitorSelectorNilUsesHelmValues=false --wait
```{{exec}}

## accessing the dashboards

```bash
kubectl port-forward svc/prometheus-kube-prometheus-prometheus 9090:9090
```{{exec}}

```bash
kubectl port-forward svc/prometheus-grafana 3000:80
```{{exec}}

```bash
Username: admin
Password: prom-operator
```{{exec}}

```bash
kubectl port-forward svc/prometheus-kube-prometheus-alertmanager 9093:9093
```{{exec}}

## install metrics server
```bash
kubectl apply -f https://github.com/kubernetes-sigs/metrics-server/releases/latest/download/components.yaml
```
```bash
kubectl -n kube-system patch deployment metrics-server --type='json' -p='[{"op": "add", "path": "/spec/template/spec/containers/0/args/-", "value": "--kubelet-insecure-tls"}]'
```{{exec}}

## deploy k8sgpt operator

```bash
helm repo add k8sgpt https://charts.k8sgpt.ai
helm repo update
```{{exec}}

```bash
helm install release k8sgpt/k8sgpt-operator -n k8sgpt-operator-system --create-namespace --set interplex.enabled=true --set grafanaDashboard.enabled=true --set serviceMonitor.enabled=true
```{{exec}}

## openai

```bash
export OPENAI_TOKEN=”Replace it with openai token”
```{{copy}}

```bash
kubectl create secret generic k8sgpt-openai-secret --from-literal=OPENAI_TOKEN=$OPENAI_TOKEN -n k8sgpt-operator-system
```{{exec}}

```bash
kubectl apply -f - <<EOF
apiVersion: core.k8sgpt.ai/v1alpha1
kind: K8sGPT
metadata:
  name: k8sgpt-sample
  namespace: k8sgpt-operator-system
spec:
  ai:
    enabled: true
    model: gpt-3.5-turbo
    backend: openai
    secret:
      name: k8sgpt-openai-secret
      key: OPENAI_TOKEN
  noCache: false
  version: v0.3.48
EOF
```{{exec}}


```bash
kubectl get all -n k8sgpt-operator-system
```{{exec}}

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
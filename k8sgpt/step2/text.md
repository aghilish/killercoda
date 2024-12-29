# k8spt operator - the 24/7 SRE assistant

## prerequisites

- prometheus
```bash
helm repo add prometheus-community https://prometheus-community.github.io/helm-charts
helm repo update
```{{exec}}

```bash
helm upgrade --install prometheus prometheus-community/kube-prometheus-stack --set prometheus.prometheusSpec.serviceMonitorSelectorNilUsesHelmValues=false --create-namespace -n monitoring --wait
```{{exec}}

- accessing the dashboards

```bash
kubectl apply -f - <<EOF
apiVersion: v1
kind: Service
metadata:
  name: prometheus-nodeport
  namespace: monitoring
spec:
  type: NodePort
  selector:
    app.kubernetes.io/name: prometheus
  ports:
    - protocol: TCP
      port: 9090
      targetPort: 9090
      nodePort: 32090
---
apiVersion: v1
kind: Service
metadata:
  name: grafana-nodeport
  namespace: monitoring
spec:
  type: NodePort
  selector:
    app.kubernetes.io/name: grafana
  ports:
    - protocol: TCP
      port: 80
      targetPort: 3000
      nodePort: 32030
---
apiVersion: v1
kind: Service
metadata:
  name: alertmanager-nodeport
  namespace: monitoring
spec:
  type: NodePort
  selector:
    app.kubernetes.io/name: alertmanager
  ports:
    - protocol: TCP
      port: 9093
      targetPort: 9093
      nodePort: 32093
EOF
```{{exec}}

[PROMETHEUS]({{TRAFFIC_HOST1_32090}})

[GRAFANA]({{TRAFFIC_HOST1_32030}})
```bash
# GRAFANA login
Username: admin
Password: prom-operator
```

[ALERT MANAGER]({{TRAFFIC_HOST1_32093}})


- install metrics server
```bash
kubectl apply -f https://github.com/kubernetes-sigs/metrics-server/releases/latest/download/components.yaml
```{{exec}}
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
  noCache: true
  version: v0.3.48
EOF
```{{exec}}

```bash
kubectl get all -n k8sgpt-operator-system
```{{exec}}


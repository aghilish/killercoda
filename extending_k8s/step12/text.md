let us perform an update on our resource and use the `alpine` image tag instead of `latest`.
So, let us replace `config/samples/blog_v1_ghost.yaml` with the following and apply it.

```yaml
apiVersion: blog.example.com/v1
kind: Ghost
metadata:
  name: ghost-sample
  namespace: marketing
spec:
  imageTag: alpine
```

Before applying the new update, please make sure the operator is running.

```shell
make run
```{{exec}}

```shell
kubectl apply -f config/samples/blog_v1_ghost.yaml
```{{exec}}

We can see that our deployment subresource is being updated and the update logs are showing up in the console. We can confirm this by inspecting the deployment.

```shell
kubectl get deploy -n marketing -ojson | jq -r '.items[].spec.template.spec.containers[0].image'
```{{exec}}

Let's first check the (defaulting)/mutating web hook.
let us make sure the marketing namespace exists.
```bash
kubectl create namespace marketing
```{{exec}}
and use the following ghost resource `config/samples/blog_v1_ghost.yaml`.

```yaml
apiVersion: blog.example.com/v1
kind: Ghost
metadata:
  name: ghost-sample
  namespace: marketing
spec:
  imageTag: alpine
```
as you can see the `replicas` field is not set, therefore the defaulting webhook should 
intercept the resource creation and set the replicas to `2` as we defined above.

let us make sure that is the case.

```bash
kubectl apply -f config/samples/blog_v1_ghost.yaml
```{{exec}}

and check the number of replicas on the ghost resouce we see it is set to `2`.
```bash
kubectl get ghosts.blog.example.com -n marketing ghost-sample -o jsonpath="{.spec.replicas}" | yq
```{{exec}}

```bash
2
```

let us check the number of replicas (pods) of our ghost deployment managed resource, to confirm that in action.
```bash
kubectl get pods -n marketing
```{{exec}}

```bash
NAME                                      READY   STATUS    RESTARTS      AGE
ghost-deployment-68rl2-85b796bd67-hzs6f   1/1     Running   1 			  2m
ghost-deployment-68rl2-85b796bd67-pczwx   1/1     Running   0             2m
```
Yep! 

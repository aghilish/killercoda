
Ok, now let us check if the validation webhook is also working as expected.
If you remember from the above, we reject custom resources with `replicas > 5`.
so let us apply the following resouce with `6` replicas.
```bash
apiVersion: blog.example.com/v1
kind: Ghost
metadata:
  name: ghost-sample
  namespace: marketing
spec:
  imageTag: alpine
  replicas: 6
```
`config/samples/blog_v1_ghost.yaml`.

```bash
kubectl apply -f config/samples/blog_v1_ghost.yaml 
```
yep! and we get 
```bash
Error from server (Forbidden): error when applying patch:
{"metadata":{"annotations":{"kubectl.kubernetes.io/last-applied-configuration":"{\"apiVersion\":\"blog.example.com/v1\",\"kind\":\"Ghost\",\"metadata\":{\"annotations\":{},\"name\":\"ghost-sample\",\"namespace\":\"marketing\"},\"spec\":{\"imageTag\":\"alpine\",\"replicas\":6}}\n"}},"spec":{"replicas":6}}
to:
Resource: "blog.example.com/v1, Resource=ghosts", GroupVersionKind: "blog.example.com/v1, Kind=Ghost"
Name: "ghost-sample", Namespace: "marketing"
for: "config/samples/blog_v1_ghost.yaml": error when patching "config/samples/blog_v1_ghost.yaml": admission webhook "vghost.kb.io" denied the request: ghost replicas cannot be more than 5
```
our validation webhook has rejected the admission review with our custom error message in the last line.
```bash
ghost replicas cannot be more than 5
```
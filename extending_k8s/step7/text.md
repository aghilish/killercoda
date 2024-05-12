now let us try to access our custom resource in the `reconcile` function. 
first off, let us reflect our new fields in our cutom resource.
let us replace `config/samples/blog_v1_ghost.yaml` with the following

```yaml
apiVersion: blog.example.com/v1
kind: Ghost
metadata:
  name: ghost-sample
  namespace: marketing
spec:
  imageTag: latest
```

```shell
kubectl create namespace marketing
kubectl apply -f config/samples/blog_v1_ghost.yaml
```{{exec}}

next, let us replace the `reconcile` code with the following snippet: 

```go
log := log.FromContext(ctx)
ghost := &blogv1.Ghost{}
if err := r.Get(ctx, req.NamespacedName, ghost); err != nil {
  log.Error(err, "Failed to get Ghost")
  return ctrl.Result{}, client.IgnoreNotFound(err)
}

log.Info("Reconciling Ghost", "imageTag", ghost.Spec.ImageTag, "team", ghost.ObjectMeta.Namespace)
log.Info("Reconciliation complete")
return ctrl.Result{}, nil
``` 

let us anlyze the above snippet line by line. 
- line 1 assings a logger instance to the variable `log` variable.
- line 2 creates an instance of our `Ghost` data structure.
- line 3 tries to read a ghost instance from the reconciler client. Please note that the r which is a reference to the `GhostReconciler` has a k8s client interface and that interface which implements the `Get` method which is an equivalent golang implementation of the `kubectl get`. on succesful `Get` the resouce will be written to our `ghost` variable. in case of error, client logs the error. if the error is of type (not found) the controller won't return an error. error not found will happen if we run `kubectl delete -f config/samples/blog_v1_ghost.yaml`

now we can start our application again:

```shell
make run
```{{exec}}

so far our reconcile function is not run yet but if we apply our custom resource in another terminal window:

```shell
kubectl apply -f config/crd/samples/blog_v1_ghost.yaml
```{{exec}}

we start to see the logs of our reconcile function

```shell
INFO    Reconciling Ghost       {"controller": "ghost", "controllerGroup": "blog.example.com", "controllerKind": "Ghost", "Ghost": {"name":"ghost-sample","namespace":"marketing"}, "namespace": "marketing", "name": "ghost-sample", "reconcileID": "9faf1c4f-6dcf-42d5-9f16-fbebb453b4ed", "imageTag": "latest", "team": "marketing"}
2024-04-29T15:54:05+02:00       

INFO    Reconciliation complete {"controller": "ghost", "controllerGroup": "blog.example.com", "controllerKind": "Ghost", "Ghost": {"name":"ghost-sample","namespace":"marketing"}, "namespace": "marketing", "name": "ghost-sample", "reconcileID": "9faf1c4f-6dcf-42d5-9f16-fbebb453b4ed"}
```

cool! next stop, we will implement the actual controller logic for our ghost operator.
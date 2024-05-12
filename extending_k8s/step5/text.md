let us add some logs to the reconcile function and run the operator application and change the state of the cluster.
let us paste this code into the `Reconcile` function. 

```go
log := log.FromContext(ctx)
log.Info("Reconciling Ghost")
log.Info("Reconciliation complete")
return ctrl.Result{}, nil
```

and run the application

```shell
make run
```{{exec}}

next we need to modify the generated custom resource yaml file
navigate to `config/samples/blog_v1_ghost.yaml`
and add a `foo: bar` under spec. The custom resource should look like 

```yaml
apiVersion: blog.example.com/v1
kind: Ghost
metadata:
  name: ghost-sample
spec:
  foo: bar
```

don't forget to save the file. Now in other terminal window, let's apply it on the cluster.
```shell
kubectl apply -f config/samples/blog_v1_ghost.yaml
```{{exec}}

Tada! checkout the logs showing up!

```shell
INFO    Reconciling Ghost
INFO    Reconciliation complete
```

now let us try deleting the resource. 

```shell
kubectl delete -f config/samples/blog_v1_ghost.yaml
```{{exec}}

Same logs showed up again. So basically _anytime_ you interact with your `Ghost` resource a new event is triggered and your controller will print the logs.

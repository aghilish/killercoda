Before we implement the validation logic let us handle the new replicas field in our controller.

let's render new manifests first

```bash
make manifests
```{{exec}}
Now are CRD is updated.

and update our controller as follows.
Update `generateDesiredDeployment` at `internal/controller/ghost_controller.go:243`

with the following
```go
replicas := ghost.Spec.Replicas
```

and the update condition at `addOrUpdateDeployment` at `internal/controller/ghost_controller.go:243`
```go
existingDeployment.Spec.Template.Spec.Containers[0].Image != desiredDeployment.Spec.Template.Spec.Containers[0].Image ||
			*existingDeployment.Spec.Replicas != *desiredDeployment.Spec.Replicas
```

and let's make sure we don't have any build error by running 
```bash
make
```{{exec}}

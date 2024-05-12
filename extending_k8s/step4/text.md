When you selected to create a operator along with the `Ghost` Resource, Kubebuilder took care of some key setup:

1. Starts the operator process during application boot
2. Implements a custom Reconcile function to run on each `Ghost` resource event
3. Configures the operator to know which resource events to listen to

To see the start process, navigate to `cmd/main.go:125`. You will see a section that starts the ghost operator:
```go
if err = (&controllers.WebsiteReconciler{
  Client: mgr.GetClient(),
  Scheme: mgr.GetScheme(),
}).SetupWithManager(mgr); err != nil {
  setupLog.Error(err, "unable to create controller", "controller", "Website")
  os.Exit(1)
}
```

This is a call to the function `SetupWithManager(mgr)` defined in the file `internal/controller/ghost_controller.go`.

Navigate to `internal/controller/ghost_controller.go:58` to view this function. 
It is already configured to know about the CRD `api/v1/ghost_types.go` or the generated yaml represenation at `crd/bases/blog.example.com_ghosts`.

The most important function inside the controller is the `Reconcile` function `internal/controller/ghost_controller.go:49`.  Reconcile is part of the main kubernetes reconciliation loop which aims to move the current state of the cluster closer to the desired state. It is triggered anytime we change the cluster state related to our custom resource `internal/controller/ghost_controller.go:49`.

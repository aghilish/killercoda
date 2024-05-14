Next we need to use our helper functions and write our reconcile function. We start by calling the functions we added one by one. 
In case there is an error we update the status of our ghost deployment. For that, we need to make a couple of adjustments first.
First we replace `GhostStatus` in `api/v1/ghost_types.go` with the following

```go
type GhostStatus struct {
    Conditions []metav1.Condition `json:"conditions,omitempty"`
}
```

and we add two helper functions to our controller. `internal/controller/ghost_controller.go`

```go
// Function to add a condition to the GhostStatus
func addCondition(status *blogv1.GhostStatus, condType string, statusType metav1.ConditionStatus, reason, message string) {
	for i, existingCondition := range status.Conditions {
		if existingCondition.Type == condType {
			// Condition already exists, update it
			status.Conditions[i].Status = statusType
			status.Conditions[i].Reason = reason
			status.Conditions[i].Message = message
			status.Conditions[i].LastTransitionTime = metav1.Now()
			return
		}
	}

	// Condition does not exist, add it
	condition := metav1.Condition{
		Type:               condType,
		Status:             statusType,
		Reason:             reason,
		Message:            message,
		LastTransitionTime: metav1.Now(),
	}
	status.Conditions = append(status.Conditions, condition)
}

// Function to update the status of the Ghost object
func (r *GhostReconciler) updateStatus(ctx context.Context, ghost *blogv1.Ghost) error {
	// Update the status of the Ghost object
	if err := r.Status().Update(ctx, ghost); err != nil {
		return err
	}

	return nil
}
```
And finally our reconcile function should be replaced with the following snippet.

```go
func (r *GhostReconciler) Reconcile(ctx context.Context, req ctrl.Request) (ctrl.Result, error) {
	log := log.FromContext(ctx)
	ghost := &blogv1.Ghost{}
	if err := r.Get(ctx, req.NamespacedName, ghost); err != nil {
		log.Error(err, "Failed to get Ghost")
		return ctrl.Result{}, client.IgnoreNotFound(err)
	}
	// Initialize completion status flags
	// Add or update the namespace first
	pvcReady := false
	deploymentReady := false
	serviceReady := false
	log.Info("Reconciling Ghost", "imageTag", ghost.Spec.ImageTag, "team", ghost.ObjectMeta.Namespace)
	// Add or update PVC
	if err := r.addPvcIfNotExists(ctx, ghost); err != nil {
		log.Error(err, "Failed to add PVC for Ghost")
		addCondition(&ghost.Status, "PVCNotReady", metav1.ConditionFalse, "PVCNotReady", "Failed to add PVC for Ghost")
		return ctrl.Result{}, err
	} else {
		pvcReady = true
	}
	// Add or update Deployment
	if err := r.addOrUpdateDeployment(ctx, ghost); err != nil {
		log.Error(err, "Failed to add or update Deployment for Ghost")
		addCondition(&ghost.Status, "DeploymentNotReady", metav1.ConditionFalse, "DeploymentNotReady", "Failed to add or update Deployment for Ghost")
		return ctrl.Result{}, err
	} else {
		deploymentReady = true
	}
	// Add or update Service
	if err := r.addServiceIfNotExists(ctx, ghost); err != nil {
		log.Error(err, "Failed to add Service for Ghost")
		addCondition(&ghost.Status, "ServiceNotReady", metav1.ConditionFalse, "ServiceNotReady", "Failed to add Service for Ghost")
		return ctrl.Result{}, err
	} else {
		serviceReady = true
	}
	// Check if all subresources are ready
	if pvcReady && deploymentReady && serviceReady {
		// Add your desired condition when all subresources are ready
		addCondition(&ghost.Status, "GhostReady", metav1.ConditionTrue, "AllSubresourcesReady", "All subresources are ready")
	}
	log.Info("Reconciliation complete")
	if err := r.updateStatus(ctx, ghost); err != nil {
		log.Error(err, "Failed to update Ghost status")
		return ctrl.Result{}, err
	}

	return ctrl.Result{}, nil
}
```
now, let us run our operator application. Before we do that, let's make sure we are starting from scratch.

```shell
kubectl delete namespace marketing
```{{exec}}

```shell
make run
```{{exec}}

we can see the logs and see that our operator application is up and running, 
in another termainl we create a ghost resource.

```shell
kubectl create namespace marketing
```{{exec}}

```shell
kubectl apply -f config/samples/blog_v1_ghost.yaml
```{{exec}}

We start to see our reconciliation logs showing up and our subresources being created. We can inspect them by running 

```shell
kubectl get pvc,deploy,svc -n marketing
```{{exec}}

Let us have a look at our ghost resource as well.
```shell
kubectl describe -n marketing ghosts.blog.example.com ghost-sample
```{{exec}}


We can perform a portforward on the service to see our ghost application in a browser.

[Ghost Application]({{TRAFFIC_HOST1_30001}})


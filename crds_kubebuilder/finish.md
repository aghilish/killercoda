# Congratulations!

You’ve completed the "Building a Custom Resource with Kubebuilder" lab! Here’s what you accomplished:
- Set up a Kubebuilder environment with Go and Kubebuilder tools.
- Initialized a project and created a "Task" CRD with a spec and status.
- Added validation rules using Kubebuilder markers.
- Generated and installed the CRD into a Kubernetes cluster.
- Created and tested a sample `Task` resource.
- Ran the controller locally and cleaned up the resources.

You’re now equipped to extend Kubernetes with your own custom resources! To take it further:
- Implement reconciliation logic in `controllers/task_controller.go` to update the `Status` (e.g., set `LastRunTime` and `Success`).
- Explore advanced validation with CEL or additional printer columns.
- Check out the [Kubebuilder Book](https://book.kubebuilder.io) for more tutorials.

Thanks for joining—happy building!
<img src="./assets/giphy.gif" alt="celebration!" width="100%">
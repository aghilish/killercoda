# Step 8: Run the Controller Locally

Let’s run the controller locally to see it in action. The controller scaffold was created in `controllers/task_controller.go`, but it’s currently minimal. For this lab, we’ll run it as-is to observe its behavior.

Generate any necessary manifests and code:

```shell
make generate
make manifests
```{{exec}}

Run the controller locally against the cluster:

```shell
make run
```{{exec}}

This starts the controller, which watches for `Task` resources. Open a new terminal tab to interact with the cluster while it runs:

```shell
kubectl get tasks.automation.example.com -n default
```{{exec}}

You’ll see logs in the controller terminal indicating it’s reconciling the `sample-task` resource. Press `Ctrl+C` in the controller terminal to stop it when you’re done observing.

> Note: The controller doesn’t update the `Status` yet because we haven’t implemented reconciliation logic. That’s an optional next step!
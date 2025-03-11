# Step 7: Create a Sample Custom Resource

Now that our "Task" CRD is installed, let’s create an instance of it.

Apply the following `Task` resource:

```shell
kubectl apply -f - << EOF
apiVersion: automation.example.com/v1
kind: Task
metadata:
  name: sample-task
  namespace: default
spec:
  command: "backup"
  schedule: "* * * * *"
EOF
```{{exec}}

This creates a `Task` named `sample-task` that runs a "backup" command every minute.

Verify it’s created:

```shell
kubectl get tasks.automation.example.com -n default
```{{exec}}

Describe the resource to see its details:

```shell
kubectl describe task sample-task -n default
```{{exec}}

Notice the `Spec` fields are set, but the `Status` is empty since we haven’t implemented the controller logic yet.
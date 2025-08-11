# Step 9: Clean Up Resources

Let’s clean up by removing the `Task` resource and the CRD.

Delete the `sample-task` resource:

```shell
kubectl delete task sample-task -n default
```{{exec}}

Verify it’s gone:

```shell
kubectl get tasks.automation.example.com -n default
```{{exec}}

Uninstall the CRD from the cluster:

```shell
make uninstall
```{{exec}}

Check that the CRD is removed:

```shell
kubectl get crds | grep tasks.automation.example.com || echo "CRD not found"
```{{exec}}

Finally, clean up the local project directory (optional, for this lab we’ll keep it):

```shell
cd .. && rm -rf task-operator
```{{exec}}

Your cluster is now back to its original state!
# Step 3: Create a Custom Resource Definition (CRD)

Now, let’s define a "Task" resource to manage automated tasks.

Run the Kubebuilder command to create the API:

```shell
kubebuilder create api \
  --kind Task \
  --group automation \
  --version v1 \
  --resource true \
  --controller true
```{{exec}}

This generates:
- A CRD scaffold in `api/v1/task_types.go`.
- A controller in `controllers/task_controller.go`.

Check the generated CRD file:

```shell
cat api/v1/task_types.go
```{{exec}}

You’ll see a `TaskSpec` struct with a sample `Foo` field and a `TaskStatus` struct. We’ll customize these next.
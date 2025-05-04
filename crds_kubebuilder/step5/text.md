# Step 5: Add Validation with Markers

Let’s add validation to ensure the `Schedule` field is immutable and the `Command` follows a pattern.

Edit `api/v1/task_types.go` again to add markers above `TaskSpec`:

```shell
// +kubebuilder:validation:XValidation:rule="self.schedule == oldSelf.schedule",message="Schedule is immutable"
```{{copy}}

```shell
// +kubebuilder:validation:Pattern=`^[a-zA-Z][a-zA-Z0-9]*$`
```{{copy}}    

The updated `TaskSpec` section now looks like:

```shell
// +kubebuilder:validation:XValidation:rule="self.schedule == oldSelf.schedule",message="Schedule is immutable"
type TaskSpec struct {
    // +kubebuilder:validation:Pattern=`^[a-zA-Z][a-zA-Z0-9]*`
    Command string `json:"command"` // Command to execute
    Schedule string `json:"schedule"` // Schedule in cron format
}
```

<!--
XValidation makes Schedule immutable using CEL.

Pattern ensures Command starts with a letter and contains only alphanumeric characters.
-->
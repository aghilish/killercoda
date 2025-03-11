# Step 5: Add Validation with Markers

Let’s add validation to ensure the `Schedule` field is immutable and the `Command` follows a pattern.

Edit `api/v1/task_types.go` again to add markers above `TaskSpec`:

```shell
sed -i '/type TaskSpec struct {/i \
\/\/ +kubebuilder:validation:XValidation:rule="self == oldSelf",message="Schedule is immutable"\n\
\/\/ +kubebuilder:validation:Pattern=`^[a-zA-Z][a-zA-Z0-9]*$`' api/v1/task_types.go
```{{exec}}

The updated `TaskSpec` section now looks like:

```go
// +kubebuilder:validation:XValidation:rule="self == oldSelf",message="Schedule is immutable"
// +kubebuilder:validation:Pattern=`^[a-zA-Z][a-zA-Z0-9]*`
type TaskSpec struct {
    Command string `json:"command"` // Command to execute
    Schedule string `json:"schedule"` // Schedule in cron format
}
```

<!--
XValidation makes Schedule immutable using CEL.

Pattern ensures Command starts with a letter and contains only alphanumeric characters.
-->
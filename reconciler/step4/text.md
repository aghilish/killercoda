# Step 4: Define the Spec and Status

Let’s customize the `Task` resource by editing `api/v1/task_types.go` to define its desired state (Spec) and observed state (Status).

Replace the default `TaskSpec` and `TaskStatus` with:

```shell
cat << EOF > api/v1/task_types.go
package v1

import (
    metav1 "k8s.io/apimachinery/pkg/apis/meta/v1"
)

// +kubebuilder:object:root=true
// +kubebuilder:subresource:status

// Task is the Schema for the tasks API
type Task struct {
    metav1.TypeMeta   \`json:",inline"\`
    metav1.ObjectMeta \`json:"metadata,omitempty"\`

    Spec   TaskSpec   \`json:"spec,omitempty"\`
    Status TaskStatus \`json:"status,omitempty"\`
}

// TaskSpec defines the desired state of Task
type TaskSpec struct {
    Command string \`json:"command"\` // Command to execute
    Schedule string \`json:"schedule"\` // Schedule in cron format
}

// TaskStatus defines the observed state of Task
type TaskStatus struct {
    LastRunTime string \`json:"lastRunTime,omitempty"\` // Last execution time
    Success bool \`json:"success,omitempty"\` // Success status of last run
}

// +kubebuilder:object:root=true

// TaskList contains a list of Task
type TaskList struct {
    metav1.TypeMeta \`json:",inline"\`
    metav1.ListMeta \`json:"metadata,omitempty"\`
    Items           []Task \`json:"items"\`
}

func init() {
    SchemeBuilder.Register(&Task{}, &TaskList{})
}
EOF
```{{exec}}

This defines a `Task` with a command to run and a schedule, plus a status tracking the last run’s time and success.
Next we are gonna add a defaulting and validating logic to our admission webhook. If the replicas is set to 0 we set it to 2 and if during create or update the replicas is set to a value bigger than 5 the validation fails. let's replace the content of our webhook at `api/v1/ghost_webhook.go` with the following.

```go
package v1

import (
	"fmt"

	"k8s.io/apimachinery/pkg/runtime"
	ctrl "sigs.k8s.io/controller-runtime"
	logf "sigs.k8s.io/controller-runtime/pkg/log"
	"sigs.k8s.io/controller-runtime/pkg/webhook"
	"sigs.k8s.io/controller-runtime/pkg/webhook/admission"
)

// log is for logging in this package.
var ghostlog = logf.Log.WithName("ghost-resource")

// SetupWebhookWithManager will setup the manager to manage the webhooks
func (r *Ghost) SetupWebhookWithManager(mgr ctrl.Manager) error {
	return ctrl.NewWebhookManagedBy(mgr).
		For(r).
		Complete()
}

// TODO(user): EDIT THIS FILE!  THIS IS SCAFFOLDING FOR YOU TO OWN!

//+kubebuilder:webhook:path=/mutate-blog-example-com-v1-ghost,mutating=true,failurePolicy=fail,sideEffects=None,groups=blog.example.com,resources=ghosts,verbs=create;update,versions=v1,name=mghost.kb.io,admissionReviewVersions=v1

var _ webhook.Defaulter = &Ghost{}

// Default implements webhook.Defaulter so a webhook will be registered for the type
func (r *Ghost) Default() {
	ghostlog.Info("default", "name", r.Name)

	if r.Spec.Replicas == 0 {
		r.Spec.Replicas = 2
	}
}

// TODO(user): change verbs to "verbs=create;update;delete" if you want to enable deletion validation.
//+kubebuilder:webhook:path=/validate-blog-example-com-v1-ghost,mutating=false,failurePolicy=fail,sideEffects=None,groups=blog.example.com,resources=ghosts,verbs=create;update,versions=v1,name=vghost.kb.io,admissionReviewVersions=v1

var _ webhook.Validator = &Ghost{}

// ValidateCreate implements webhook.Validator so a webhook will be registered for the type
func (r *Ghost) ValidateCreate() (admission.Warnings, error) {
	ghostlog.Info("validate create", "name", r.Name)
	return validateReplicas(r)
}

// ValidateUpdate implements webhook.Validator so a webhook will be registered for the type
func (r *Ghost) ValidateUpdate(old runtime.Object) (admission.Warnings, error) {
	ghostlog.Info("validate update", "name", r.Name)
	return validateReplicas(r)
}

// ValidateDelete implements webhook.Validator so a webhook will be registered for the type
func (r *Ghost) ValidateDelete() (admission.Warnings, error) {
	ghostlog.Info("validate delete", "name", r.Name)

	// TODO(user): fill in your validation logic upon object deletion.
	return nil, nil
}

func validateReplicas(r *Ghost) (admission.Warnings, error) {
	if r.Spec.Replicas > 5 {
		return nil, fmt.Errorf("ghost replicas cannot be more than 5")
	}
	return nil, nil
}

```
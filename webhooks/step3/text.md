let's pick up where we left off last time by cloning our ghost operator tutorial.

```bash
git clone https://github.com/aghilish/operator-tutorial.git
cd operator-tutorial
```

let's create our first webhook
```bash
kubebuilder create webhook --kind Ghost --group blog --version v1 --defaulting --programmatic-validation
```
Let's have a look at the `api/v1/ghost_webhook.go` file, you should notice that some boilerplate code was generated for us to implement Mutating and Validating webhook logic.

Next we are gonna add a new field to our ghost spec called `replicas`. As you might have guessed this field is there to set the number of replicas on the managed deployment resource which we set on our ghost resource.

ok let's add the following line to our `GhostSpec` struct `api/v1/ghost_types.go:30`.

```go
//+kubebuilder:validation:Minimum=1
Replicas int32 `json:"replicas"`
```
Please note the kubebuilder marker. It validates the replicas value to be at least 1. But it's an optional value.
This validation marker will then translate into our custom resource definition. This type of validation is called declarartive validation.
With `Validating Admission Webhooks` we can validate our resources in a programmatic way meaning the webhook can return errors with custome messages if programmatic validation fails. In our `Mutating Validation Webhook` we can mutate our resource or set a default for replias if nothing is set on the custom resource manifest. 

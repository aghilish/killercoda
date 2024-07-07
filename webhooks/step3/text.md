first off, let us make sure go, kubebuilder and k9s are installed.

```bash
# download kubebuilder and install locally.
curl -L -o kubebuilder "https://go.kubebuilder.io/dl/latest/$(go env GOOS)/$(go env GOARCH)"
chmod +x kubebuilder && mv kubebuilder /usr/local/bin/
```{{exec}}

Let's make sure we have the latest version of GO installed.

```bash
curl -OL  https://go.dev/dl/go1.22.3.linux-amd64.tar.gz \
&&  rm -rf /usr/local/go && tar -C /usr/local -xzf go1.22.3.linux-amd64.tar.gz \
&& export PATH=$PATH:/usr/local/go/bin
```{{exec}}

and finally, k9s.

```bash
curl -L -O https://github.com/derailed/k9s/releases/download/v0.32.5/k9s_linux_amd64.deb \
&& dpkg -i k9s_linux_amd64.deb
```

We pick up where we left off last time by cloning our ghost operator tutorial.

```bash
git clone https://github.com/aghilish/operator-tutorial.git
cd operator-tutorial
```{{exec}}

let's create our first webhook

```bash
kubebuilder create webhook --kind Ghost --group blog --version v1 --defaulting --programmatic-validation
```{{exec}}

Let's have a look at the `api/v1/ghost_webhook.go` file, you should notice that some boilerplate code was generated for us to implement Mutating and Validating webhook logic.

Next we are gonna add a new field to our ghost spec called `replicas`. As you might have guessed this field is there to set the number of replicas on the managed deployment resource which we set on our ghost resource.

ok let's add the following line to our `GhostSpec` struct `api/v1/ghost_types.go:30`.

<pre><code>
//+kubebuilder:validation:Minimum=1
Replicas int32 `json:"replicas"`
</code></pre>

Please note the kubebuilder marker. It validates the replicas value to be at least 1. But it's an optional value.
This validation marker will then translate into our custom resource definition. This type of validation is called schema validation.
With `Validating Admission Webhooks` we can validate our resources in a programmatic way meaning the webhook can return errors with custome messages if programmatic validation fails. In our `Mutating Validation Webhook` we can mutate our resource or set a default for replias if nothing is set on the custom resource manifest. 

Now we have a working yet empty go application. 
let's add some meaningful code to it.

Let's imagine we are a working at company where our colleagues are heavy users of the `ghost` blogging application.
Our job is to provide them with ghost instances whenever and whereever they want it. We are infra gurus and through years of
experience have learned that building an automation for such a task can save us a lot of toil and manual labor.

Our operator will take care of the following: 
1. create a new instance of the ghost application as a website in our cluster if our cluster doesn't have it already
2. update our ghost application when our ghost application custom resource is updated.
3. delete the ghost application upon request 

Kubebuilder provides a command that allows us to create a custom resource and a process that keeps maintaing (reconciling) that resouce.
If we choose to create a new resouces (let's call it `Ghost`) kubebuilder will create a blog controller for it automatically.
If we want to attach our own controllers to the exisiting k8s resources say `Pods` that's posssible too! :D 

```shell
kubebuilder create api \
  --kind Ghost \
  --group blog \
  --version v1 \
  --resource true \
  --controller true
```{{exec}}

At this stage, Kubebuilder has wired up two key components for your operator.

- A Resource in the form of a Custom Resource Definition (CRD) with the kind `Ghost`.
- A Controller that runs each time a `Ghost` CRD is create, changed, or deleted.

The command we ran added a Golang representation of the `Ghost` Custom Resource Definition (CRD) to our operator scaffolding code.
To view this code, navigate to your Code editor tab under `api` > `v1` > `ghost_types.go`.

Let us have a look at the `type GhostSpec struct`. 
This is the code definition of the Kubernetes object spec. This spec contains a field named `foo` which is defined in `api/v1/ghost_types.go:32`. 
There is even a helpful comment above the field describing the use of foo.


now let us see how kubebuilder can generate a yaml file for our `Custom Resource Definition`
```shell
make manifests
```{{exec}}

you will find the generated crd at `config/crd/bases/blog.example.com_ghosts.yaml`
see how kubebuilder did all the heavylifting we had to previously do for the crontab example! lovely!


Now let us install the CRD into our cluster
and notice the difference by looking at our kubernetes crds.

```shell
kubectl get crds
```{{exec}}

now let us install the crd we generated onto the cluster
```shell
make install
```{{exec}}

and run the get the crds again

```shell
kubectl get crds
```{{exec}}

Now let us replace the default GhostSpec with a meaningful declartion of our desired state. Meaning we want our custom resource reflect the desired state for our Ghost application.

replace GhostSpec `api/v1/ghost_types.go:27` with the following snippet

```go
type GhostSpec struct {
  //+kubebuilder:validation:Pattern=`^[-a-z0-9]*$`
  ImageTag string `json:"imageTag"`
}
```

This code has two key parts:

- `//+kubebuilder` is a comment prefix that will trigger kubebuilder generation changes. In this case, it will set a validation of the `ImageTag` value to only allow dashes, lowercase letters, or digits.
- The `ImageTag` is the Golang variable used throughout the codebase. Golang uses capitalized public variable names by convention.
`json:"imageTag"` defines a "tag" that Kubebuilder uses to generate the YAML field. Yaml parameters starts with lower case variable names by convention.
If `omitempty` is used in a json tag, that field will be marked as `optional`, otherwise as `mandatory`.

Before we generete the new crd and install them on the cluster let's do the following, let's have a look at the existing crd

```shell
kubectl get crd ghosts.blog.example.com --output jsonpath="{.spec.versions[0].schema['openAPIV3Schema'].properties.spec.properties}{\"\n\"}" | jq
```{{exec}}

the output should be like 

```json
{
  "foo": {
    "description": "Foo is an example field of Ghost. Edit ghost_types.go to remove/update",
    "type": "string"
  }
}

```
now, let us install the new crd

```shell
make install
```{{exec}}

and see the changes

```shell
kubectl get crd ghosts.blog.example.com --output jsonpath="{.spec.versions[0].schema['openAPIV3Schema'].properties.spec.properties}{\"\n\"}" | jq
```{{exec}}

the output should be 

```json
{
  "imageTag": {
    "pattern": "^[-a-z0-9]*$",
    "type": "string"
  }
}
```
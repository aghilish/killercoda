Next, we need to specify the kubebuilder markers for RBAC. After we created our apis there are 3 markers generated bu default.

```go
//+kubebuilder:rbac:groups=blog.example.com,resources=ghosts,verbs=get;list;watch;create;update;patch;delete
//+kubebuilder:rbac:groups=blog.example.com,resources=ghosts/status,verbs=get;update;patch
//+kubebuilder:rbac:groups=blog.example.com,resources=ghosts/finalizers,verbs=update
```
These markers with `//+kubebuilder` prefix are picked up by `make manfists` where a `ClusterRole` manifests is generated and assiged to the operator manager application. When we CRUD other APIs such as deployment, services and Persistent Volume Claims, we need to add those related markers, otherwise our operator will be unauthorized to perform those operations. In case of our operator, we need to additional markers right below the default ones at `internal/controller/ghost_controller.go`.

```go
//+kubebuilder:rbac:groups=blog.example.com,resources=ghosts/events,verbs=get;list;watch;create;update;patch
//+kubebuilder:rbac:groups="",resources=persistentvolumeclaims,verbs=get;list;watch;create;update;patch;delete
//+kubebuilder:rbac:groups=apps,resources=deployments,verbs=get;list;watch;create;update;patch;delete
//+kubebuilder:rbac:groups="",resources=services,verbs=get;list;watch;create;update;patch;delete
```

Please note the first one, is needed when we later introduce a function to persist operator events in the ghost resource.
To generate RBAC manfiests, we can run

```shell
make manifests
```{{exec}}

The generated manifest for the manager cluster role, will be generated at `config/rbac/role.yaml`
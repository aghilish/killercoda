let's start by using the `custom resource definition` api of kubernetes. 
let's create a custom resource called `CronTab`

```
kubectl apply -f - << EOF
apiVersion: apiextensions.k8s.io/v1
kind: CustomResourceDefinition
metadata:
  # name must match the spec fields below, and be in the form: <plural>.<group>
  name: crontabs.stable.example.com
spec:
  # group name to use for REST API: /apis/<group>/<version>
  group: stable.example.com
  # list of versions supported by this CustomResourceDefinition
  versions:
    - name: v1
      # Each version can be enabled/disabled by Served flag.
      served: true
      # One and only one version must be marked as the storage version.
      storage: true
      schema:
        openAPIV3Schema:
          type: object
          properties:
            spec:
              type: object
              properties:
                cronSpec:
                  type: string
                image:
                  type: string
                replicas:
                  type: integer
      
      additionalPrinterColumns:
        - name: Spec
          type: string
          description: The cron spec defining the interval a CronJob is run
          jsonPath: .spec.cronSpec
        - name: Replicas
          type: integer
          description: The number of jobs launched by the CronJob
          jsonPath: .spec.replicas
        - name: Age
          type: date
          jsonPath: .metadata.creationTimestamp
  # either Namespaced or Cluster
  scope: Namespaced
  names:
    # plural name to be used in the URL: /apis/<group>/<version>/<plural>
    plural: crontabs
    # singular name to be used as an alias on the CLI and for display
    singular: crontab
    # kind is normally the CamelCased singular type. Your resource manifests use this.
    kind: CronTab
    # shortNames allow shorter string to match your resource on the CLI
    shortNames:
    - ct
EOF
```{{exec}}

now our CronTab resource type is created. 
`kubectl get crd`{{exec}}

A new namespaced RESTful API endpoint is created at:

```shell
/apis/stable.example.com/v1/namespaces/*/crontabs/...
```

Let's verify the k8s api extension by looking at the api server logs:

`kubectl -n kube-system logs -f kube-apiserver-kind-control-plane | grep example.com`{{exec}}

Now we can create custom objects of our new custom resource defintion.
In the following example, the `cronSpec` and `image` custom fields are set in a custom object of kind `CronTab`. 
The kind `CronTab` comes from the `spec` of the CustomResourceDefinition object you created above.

```shell
kubectl apply -f - << EOF
apiVersion: "stable.example.com/v1"
kind: CronTab
metadata:
  name: my-new-cron-object
spec:
  cronSpec: "* * * * */5"
  image: my-awesome-cron-image
EOF
```{{exec}}

`kubectl get crontab`{{exec}}

Let's see how our object is being persisted at the etcd database of k8s.

`kubectl exec etcd-kind-control-plane -n kube-system -- sh -c "ETCDCTL_API=3 etcdctl --cacert /etc/kubernetes/pki/etcd/ca.crt  --key /etc/kubernetes/pki/etcd/server.key --cert  /etc/kubernetes/pki/etcd/server.crt  get / --prefix --keys-only" | grep example.com`{{exec}}

`kubectl exec etcd-kind-control-plane -n kube-system -- sh -c "ETCDCTL_API=3 etcdctl --cacert /etc/kubernetes/pki/etcd/ca.crt  --key /etc/kubernetes/pki/etcd/server.key --cert  /etc/kubernetes/pki/etcd/server.crt  get /registry/apiextensions.k8s.io/customresourcedefinitions/crontabs.stable.example.com --prefix -w json" | jq ".kvs[0].value" | cut -d '"' -f2 | base64 --decode | yq > crd.yml`{{exec}}

`kubectl exec etcd-kind-control-plane -n kube-system -- sh -c "ETCDCTL_API=3 etcdctl --cacert /etc/kubernetes/pki/etcd/ca.crt  --key /etc/kubernetes/pki/etcd/server.key --cert  /etc/kubernetes/pki/etcd/server.crt  get /registry/apiregistration.k8s.io/apiservices/v1.stable.example.com --prefix -w json" | jq ".kvs[0].value" | cut -d '"' -f2 | base64 --decode | yq > api-registration.yml`{{exec}}

`kubectl exec etcd-kind-control-plane -n kube-system -- sh -c "ETCDCTL_API=3 etcdctl --cacert /etc/kubernetes/pki/etcd/ca.crt  --key /etc/kubernetes/pki/etcd/server.key --cert  /etc/kubernetes/pki/etcd/server.crt  get /registry/stable.example.com/crontabs/default/my-new-cron-object --prefix -w json" | jq ".kvs[0].value" | cut -d '"' -f2 | base64 --decode | yq > mycron.yml`{{exec}}


Delete custom resource

`kubectl delete CronTab my-new-cron-object`{{exec}}

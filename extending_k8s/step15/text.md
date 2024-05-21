## Deploying the Operator to Kubernetes

Your operator is an application, so it needs to be packaged as a OCI compliant container image just like any other container you want to deploy.

We need to run the right make command to build our OCI image and then Deploy it.

Build
```shell
# please use your own tag here! :D 
export IMG=c8n.io/aghilish/ghost-operator:latest
make docker-build
```{{exec}}

Push
```shell
make docker-push
```{{exec}}

Deploy
```shell
make deploy
```{{exec}}

Undeploy

```shell
make undeploy
```{{exec}}

And we can look around and inspect the logs of our manager when we CRUD operations with our ghost API.

```shell
kubectl get all -n ghost-operator-system
```{{exec}}

# Step 6: Generate and Install the CRD

Generate the CRD manifest based on our definitions

```shell
make manifests
```{{exec}}

View the generated CRD:

```shell
cat config/crd/bases/automation.example.com_tasks.yaml
```{{exec}}

Install the CRD into the cluster:

```shell
make install
```{{exec}}

Verify it’s installed:

```shell
kubectl get crds | grep tasks.automation.example.com
```{{exec}}

The CRD is now available at `/apis/automation.example.com/v1/namespaces/*/tasks/...`.
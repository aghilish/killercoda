Once our webhook is implemented, all that’s left to do is to create the `WebhookConfiguration` manifests required to register our webhooks with Kubernetes. The connection between the kubernetes api and our webhook server needs to be secure and encrypted. This can easily happen if we use certmanager togehter with the powerful scaffolding of kubebuilder.

We need to enable the cert-manager deployment via kubebuilder, in order to do that we should edit `config/default/kustomization.yaml` and `config/crd/kustomization.yaml` files by uncommenting the sections marked by [WEBHOOK] and [CERTMANAGER] comments.
Once the necessary sections are uncommented, let's run
```bash
make manifests
```{{exec}}
to make sure we have the cert-manager manifests for our webhook are generated.

We also add a new target to our make file for installing cert-manager using a helm command.

So let's add the following to the botton of our make file.

```go
##@ Helm

HELM_VERSION ?= v3.7.1

.PHONY: helm
helm: ## Download helm locally if necessary.
ifeq (, $(shell which helm))
        @{ \
        set -e ;\
        curl https://raw.githubusercontent.com/helm/helm/main/scripts/get-helm-3 | bash ;\
        }
endif

.PHONY: install-cert-manager
install-cert-manager: helm ## Install cert-manager using Helm.
		helm repo add jetstack https://charts.jetstack.io
		helm repo update
		helm install cert-manager jetstack/cert-manager --namespace cert-manager --create-namespace --version v1.15.0 --set crds.enabled=true

.PHONY: uninstall-cert-manager
uninstall-cert-manager: helm ## Uninstall cert-manager using Helm.
		helm uninstall cert-manager --namespace cert-manager
		kubectl delete namespace cert-manager
```{{copy}}

cool, now let's instal cert-manage on our cluster:

```bash
make install-cert-manager
```{{exec}}

and get the pods in the cert-manager to make sure they are running
```bash
kubectl get pods -n cert-manager
```{{exec}}

```bash
NAME                                       READY   STATUS    RESTARTS   AGE
cert-manager-cainjector-698464d9bb-vq96f   1/1     Running   0          2m
cert-manager-d7db49bf4-q2gkc               1/1     Running   0          2m
cert-manager-webhook-f6c9958d-jwhr2        1/1     Running   0          2m
```{{exec}}

awesome, now let us build our new controller image and deploy everything (controller and admission webhooks)
to our cluster.

```bash
export IMG=ttl.sh/operator-tutorial-with-webhook:1h
```{{exec}}
```bash
make docker-build
```{{exec}}
```bash
make docker-push
```{{exec}}
```bash
make deploy
```{{exec}}

and check if our manager is running in the `opeator-turorial-system` namespace.

```bash
kubectl get pods -n operator-tutorial-system
```{{exec}}

```bash
NAME                                                   READY   STATUS    RESTARTS   AGE
operator-tutorial-controller-manager-db8c46dbf-58kdn   2/2     Running   0          2m
```{{exec}}

and to make sure that our webhook configurations are also deployed. we can run the following
```bash
kubectl get mutatingwebhookconfigurations.admissionregistration.k8s.io -n operator-tutorial-system
```{{exec}}

```bash
NAME                                               WEBHOOKS   AGE
cert-manager-webhook                               1          2m
operator-tutorial-mutating-webhook-configuration   1          2m
```{{exec}}

```bash
kubectl get validatingwebhookconfigurations.admissionregistration.k8s.io -n operator-tutorial-system
```{{exec}}

```bash
NAME                                                 WEBHOOKS   AGE
cert-manager-webhook                                 1          2m
operator-tutorial-validating-webhook-configuration   1          2m
```{{exec}}

we see our webhook configurations as well as the ones that belong to cert-manager and are in charge of injecting the `caBunlde`
into our webhook services.
Awesome! everything is deployed. Now let's see if the admission webhook is working as we expect.

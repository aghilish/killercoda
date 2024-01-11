
> Let's start by installing argo cd. For that you can check out the offical [Argo CD Documentation](https://argo-cd.readthedocs.io/en/stable/getting_started/).
> However we have slightly modified the manifests to able to access argo cd server within the `killercoda` environment.

`kubectl create namespace argocd`{{exec}}

`kubectl apply -n argocd -f /home/install.yaml`{{exec}}

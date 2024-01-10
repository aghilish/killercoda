
> Let's start by installing argo cd. For that you can check out the offical [Argo CD Documentation](https://argo-cd.readthedocs.io/en/stable/getting_started/).
> However we have slightly modified the manifests to able to access argo cd server within the `killercoda` environment.

<details>
  <summary>Solution</summary>
  <p>
    <pre>
      <code>
kubectl create namespace argocd
kubectl apply -n argocd -f /tmp/install.yaml
    </code>
      </pre>
    </p>
</details>
<br/>

> Now let's go ahead and install the Argo CD CLI. Please checkout the [CLI installation Documentation](https://argo-cd.readthedocs.io/en/stable/cli_installation/)

<details>
  <summary>Solution</summary>
  <p>
    <pre>
      <code>
curl -sSL -o argocd-linux-amd64 https://github.com/argoproj/argo-cd/releases/latest/download/argocd-linux-amd64
sudo install -m 555 argocd-linux-amd64 /usr/local/bin/argocd
rm argocd-linux-amd64
    </code>
      </pre>
    </p>
</details>

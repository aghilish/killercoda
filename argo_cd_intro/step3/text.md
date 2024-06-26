> Create an Argo CD application declaratively using Yaml with below specs and apply it using kubectl: You can use the definition file `/home/application.yaml` as a starting point.

- Name: `guestbook`
- Destination cluster url (local cluster): `https://kubernetes.default.svc`
- Destination namespace: `guestbook`
- Source repo: `https://github.com/aghilish/argocd-example-apps.git`, or you can fork the repo and set your repo url.
- Source path: `guestbook` , (path of manifests where it include k8s service and deployment files).
- Source branch: `master`
- Create the application using kubectl

`kubectl apply -f /home/application.yaml`{{exec}}

<details>
  <summary>Solution</summary>
  <p>
    <pre>
      <code>
apiVersion: argoproj.io/v1alpha1
kind: Application
metadata:
  name: guestbook
  namespace: argocd
spec:
  destination:
    namespace: guestbook
    server: "https://kubernetes.default.svc"
  project: default
  source:
    path: guestbook
    repoURL: "https://github.com/aghilish/argocd-example-apps.git"
    targetRevision: master
  syncPolicy:
    syncOptions:
      - CreateNamespace=true
    </code>
      </pre>
    </p>
</details>

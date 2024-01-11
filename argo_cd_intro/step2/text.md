> You need admin password in order to login to Argo CD web ui.
Initial admin password is stored as a secret in argocd namespace:

```jsx
kubectl -n argocd get secret argocd-initial-admin-secret -o jsonpath="{.data.password}" | base64 -d; echo
```

In this environment we exposed Argo CD server externally using node port.
[ACCESS ARGO CD UI]({{TRAFFIC_HOST1_32073}})

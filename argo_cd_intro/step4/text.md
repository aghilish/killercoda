>Open Argo CD web and sync the application. You need admin user password to login in web.
>Username: admin
`kubectl -n argocd get secret argocd-initial-admin-secret -o jsonpath="{.data.password}" | base64 -d echo`{{exec}}

Then click on below link to open web UI.

[ACCESS ARGO CD UI]({{TRAFFIC_HOST1_32073}})

Sync the application to create the resources in destination cluster.

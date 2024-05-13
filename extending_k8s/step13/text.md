If perform a delete operation on our resource, all the subresouces will be deleted too, as we set their owner to be the ghost resource.
Please notice the `controllerutil.SetControllerReference` usage, before creating the subresources.

Let us perform the delete and see the effect.
```shell
kubectl delete ghosts.blog.example.com -n marketing ghost-sample
```{{exec}}
We can see all the subresources are deleted.

```shell
kubectl get all -n marketing
```{{exec}}
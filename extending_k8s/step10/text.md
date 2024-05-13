
And Lastly we need to add a service for our deployment. For now let's choose a service of type `NodePort`
```yaml
apiVersion: v1
kind: Service
metadata:
  name: ghost-service
spec:
  type: NodePort
  ports:
    - port: 80 # Exposed port on the service
      targetPort: 2368 # Port your application is listening on inside the pod
      nodePort: 30001 # NodePort to access the service externally
  selector:
    app: ghost
```

Next, we need to implement a go funtion that creates such service for us.

```go
func (r *GhostReconciler) addServiceIfNotExists(ctx context.Context, ghost *blogv1.Ghost) error {
	log := log.FromContext(ctx)
	service := &corev1.Service{}
	err := r.Get(ctx, client.ObjectKey{Namespace: ghost.ObjectMeta.Namespace, Name: svcNamePrefix + ghost.ObjectMeta.Namespace}, service)
	if err != nil && client.IgnoreNotFound(err) != nil {
		return err
	}

	if err == nil {
		// Service exists
		return nil
	}
	// Service does not exist, create it
	desiredService := generateDesiredService(ghost)
	if err := controllerutil.SetControllerReference(ghost, desiredService, r.Scheme); err != nil {
		return err
	}

	// Service does not exist, create it
	if err := r.Create(ctx, desiredService); err != nil {
		return err
	}
	r.recoder.Event(ghost, corev1.EventTypeNormal, "ServiceCreated", "Service created successfully")
	log.Info("Service created", "service", desiredService.Name)
	return nil
}

func generateDesiredService(ghost *blogv1.Ghost) *corev1.Service {
	return &corev1.Service{
		ObjectMeta: metav1.ObjectMeta{
			Name:      "ghost-service-" + ghost.ObjectMeta.Namespace,
			Namespace: ghost.ObjectMeta.Namespace,
		},
		Spec: corev1.ServiceSpec{
			Type: corev1.ServiceTypeNodePort,
			Ports: []corev1.ServicePort{
				{
					Port:       80,
					TargetPort: intstr.FromInt(2368),
					NodePort:   30001,
				},
			},
			Selector: map[string]string{
				"app": "ghost-" + ghost.ObjectMeta.Namespace,
			},
		},
	}
}
```

And let's make sure the following import statements are added to the import section.

```go
"k8s.io/apimachinery/pkg/util/intstr"
```

let's rebuild the application to make sure there are no syntax errors.

```shell
make 
```{{exec}}
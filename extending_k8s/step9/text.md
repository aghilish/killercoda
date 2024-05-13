
Next, we add the deployment create and update logic to our controller. For that we copy the following snippet to our controller.
The logic is very similar to the previous snippet. However there is one key difference and that is that `addOrUpdateDeployment` can also update a deployment in case the deployed `imageTag` for the ghost image is different from the one coming from the `ghost.Spec` aka. desired state.

```go
func (r *GhostReconciler) addOrUpdateDeployment(ctx context.Context, ghost *blogv1.Ghost) error {
	log := log.FromContext(ctx)
	deploymentList := &appsv1.DeploymentList{}
	labelSelector := labels.Set{"app": "ghost-" + ghost.ObjectMeta.Namespace}

	err := r.List(ctx, deploymentList, &client.ListOptions{
		Namespace:     ghost.ObjectMeta.Namespace,
		LabelSelector: labelSelector.AsSelector(),
	})
	if err != nil {
		return err
	}

	if len(deploymentList.Items) > 0 {
		// Deployment exists, update it
		existingDeployment := &deploymentList.Items[0] // Assuming only one deployment exists
		desiredDeployment := generateDesiredDeployment(ghost)

		// Compare relevant fields to determine if an update is needed
		if existingDeployment.Spec.Template.Spec.Containers[0].Image != desiredDeployment.Spec.Template.Spec.Containers[0].Image {
			// Fields have changed, update the deployment
			existingDeployment.Spec = desiredDeployment.Spec
			if err := r.Update(ctx, existingDeployment); err != nil {
				return err
			}
			log.Info("Deployment updated", "deployment", existingDeployment.Name)
			r.recoder.Event(ghost, corev1.EventTypeNormal, "DeploymentUpdated", "Deployment updated successfully")
		} else {
			log.Info("Deployment is up to date, no action required", "deployment", existingDeployment.Name)
		}
		return nil
	}

	// Deployment does not exist, create it
	desiredDeployment := generateDesiredDeployment(ghost)
	if err := controllerutil.SetControllerReference(ghost, desiredDeployment, r.Scheme); err != nil {
		return err
	}
	if err := r.Create(ctx, desiredDeployment); err != nil {
		return err
	}
	r.recoder.Event(ghost, corev1.EventTypeNormal, "DeploymentCreated", "Deployment created successfully")
	log.Info("Deployment created", "team", ghost.ObjectMeta.Namespace)
	return nil
}

func generateDesiredDeployment(ghost *blogv1.Ghost) *appsv1.Deployment {
	replicas := int32(1) // Adjust replica count as needed
	return &appsv1.Deployment{
		ObjectMeta: metav1.ObjectMeta{
			GenerateName: deploymentNamePrefix,
			Namespace:    ghost.ObjectMeta.Namespace,
			Labels: map[string]string{
				"app": "ghost-" + ghost.ObjectMeta.Namespace,
			},
		},
		Spec: appsv1.DeploymentSpec{
			Replicas: &replicas,
			Selector: &metav1.LabelSelector{
				MatchLabels: map[string]string{
					"app": "ghost-" + ghost.ObjectMeta.Namespace,
				},
			},
			Template: corev1.PodTemplateSpec{
				ObjectMeta: metav1.ObjectMeta{
					Labels: map[string]string{
						"app": "ghost-" + ghost.ObjectMeta.Namespace,
					},
				},
				Spec: corev1.PodSpec{
					Containers: []corev1.Container{
						{
							Name:  "ghost",
							Image: "ghost:" + ghost.Spec.ImageTag,
							Env: []corev1.EnvVar{
								{
									Name:  "NODE_ENV",
									Value: "development",
								},
								{
									Name:  "database__connection__filename",
									Value: "/var/lib/ghost/content/data/ghost.db",
								},
							},
							Ports: []corev1.ContainerPort{
								{
									ContainerPort: 2368,
								},
							},
							VolumeMounts: []corev1.VolumeMount{
								{
									Name:      "ghost-data",
									MountPath: "/var/lib/ghost/content",
								},
							},
						},
					},
					Volumes: []corev1.Volume{
						{
							Name: "ghost-data",
							VolumeSource: corev1.VolumeSource{
								PersistentVolumeClaim: &corev1.PersistentVolumeClaimVolumeSource{
									ClaimName: "ghost-data-pvc-" + ghost.ObjectMeta.Namespace,
								},
							},
						},
					},
				},
			},
		},
	}
}
```
And let's make sure the following import statements are added to the import section.

```go
appsv1 "k8s.io/api/apps/v1"
"k8s.io/apimachinery/pkg/labels"
```

let's rebuild the application to make sure there are no syntax errors.

```shell
make 
```{{exec}}
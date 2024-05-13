Before we start coding the ghost operator, we need to know what resources we need in order to deploy ghost to our cluster. let's consult the docker hub page for ghost. https://hub.docker.com/_/ghost

As we would like to persist ghost data to a persistent volume, we can try to convert this docker command to a k8s deployment. 

```shell
docker run -d \
	--name some-ghost \
	-e NODE_ENV=development \
	-e database__connection__filename='/var/lib/ghost/content/data/ghost.db' \
	-p 3001:2368 \
	-v some-ghost-data:/var/lib/ghost/content \
	ghost:alpine
```

The deployment would look something like 

```yaml
apiVersion: apps/v1
kind: Deployment
metadata:
  name: ghost-deployment
spec:
  replicas: 1 # You can adjust the number of replicas as needed
  selector:
    matchLabels:
      app: ghost
  template:
    metadata:
      labels:
        app: ghost
    spec:
      containers:
      - name: ghost
        image: ghost:alpine
        env:
        - name: NODE_ENV
          value: development
        - name: database__connection__filename
          value: /var/lib/ghost/content/data/ghost.db
        ports:
        - containerPort: 2368
        volumeMounts:
        - name: ghost-data
          mountPath: /var/lib/ghost/content
      volumes:
      - name: ghost-data
        persistentVolumeClaim:
          claimName: ghost-data-pvc # Define your PVC or use an existing one
```

As you can see this deployment expects an existing persistent volume claim called `ghost-data-pvc`

We can define it with this yaml:
```yaml
apiVersion: v1
kind: PersistentVolumeClaim
metadata:
  name: ghost-data-pvc
spec:
  accessModes:
    - ReadWriteOnce
  resources:
    requests:
      storage: 1Gi
```

In our operator, each team's ghost instance will be deployed to the team's corresponding namespace.
Let us try to code the pvc provisiong into our controller. For that we need to copy the following snippet to our controller.
`internal/controller/ghost_controller.go`

```go
func (r *GhostReconciler) addPvcIfNotExists(ctx context.Context, ghost *blogv1.Ghost) error {
	log := log.FromContext(ctx)

	pvc := &corev1.PersistentVolumeClaim{}
	team := ghost.ObjectMeta.Namespace
	pvcName := pvcNamePrefix + team

	err := r.Get(ctx, client.ObjectKey{Namespace: ghost.ObjectMeta.Namespace, Name: pvcName}, pvc)

	if err == nil {
		// PVC exists, we are done here!
		return nil
	}

	// PVC does not exist, create it
	desiredPVC := generateDesiredPVC(ghost, pvcName)
	if err := controllerutil.SetControllerReference(ghost, desiredPVC, r.Scheme); err != nil {
		return err
	}

	if err := r.Create(ctx, desiredPVC); err != nil {
		return err
	}
	r.recoder.Event(ghost, corev1.EventTypeNormal, "PVCReady", "PVC created successfully")
	log.Info("PVC created", "pvc", pvcName)
	return nil
}

func generateDesiredPVC(ghost *blogv1.Ghost, pvcName string) *corev1.PersistentVolumeClaim {
	return &corev1.PersistentVolumeClaim{
		ObjectMeta: metav1.ObjectMeta{
			Name:      pvcName,
			Namespace: ghost.ObjectMeta.Namespace,
		},
		Spec: corev1.PersistentVolumeClaimSpec{
			AccessModes: []corev1.PersistentVolumeAccessMode{corev1.ReadWriteOnce},
			Resources: corev1.VolumeResourceRequirements{
				Requests: corev1.ResourceList{
					corev1.ResourceStorage: resource.MustParse("1Gi"),
				},
			},
		},
	}
}
```
Let's make sure we have the following import statements in the import section of our controller `internal/controller/ghost_controller.go`.

```go
  corev1 "k8s.io/api/core/v1"
	metav1 "k8s.io/apimachinery/pkg/apis/meta/v1"
	"k8s.io/apimachinery/pkg/api/resource"
	"sigs.k8s.io/controller-runtime/pkg/controller/controllerutil"
	"k8s.io/client-go/tools/record"
```

Also let's replace our `GhostReconciler` struct with the following snippet

```go
type GhostReconciler struct {
	client.Client
	Scheme  *runtime.Scheme
	recoder record.EventRecorder
}
```

and Let's add 

```go
const pvcNamePrefix = "ghost-data-pvc-"
const deploymentNamePrefix = "ghost-deployment-"
const svcNamePrefix = "ghost-service-"
```
right after our `GhostReconciler` struct. (around line 40).

The `addPvcIfNotExists` function, checks whether the `pvc` is already created and if not, it will create it in the right namespace.

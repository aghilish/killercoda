# Step 11: Deployment and Service Management

Now let's implement the deployment and service management logic for our MCPServer operator. This is where we create the actual Kubernetes resources that run our MCP servers.

## Initialize Kubebuilder Project

First, let's set up our operator project structure:

```bash
# Create operator workspace
mkdir -p /workspace/mcp-operator
cd /workspace/mcp-operator

# Initialize Kubebuilder project
kubebuilder init --domain mcp.example.com --repo github.com/example/mcp-operator

# Create the MCPServer API and controller
kubebuilder create api --group mcp --version v1alpha1 --kind MCPServer --controller --resource

echo "✅ MCPServer operator project initialized"
```{{exec}}

## Update MCPServer Spec

Let's update the MCPServer specification to match our needs:

```bash
# Update the MCPServer types
cat > api/v1alpha1/mcpserver_types.go << 'EOF'
package v1alpha1

import (
	metav1 "k8s.io/apimachinery/pkg/apis/meta/v1"
)

// MCPServerSpec defines the desired state of MCPServer
type MCPServerSpec struct {
	// Image is the container image for the MCP server
	// +kubebuilder:validation:Required
	Image string `json:"image"`
	
	// Port is the port the MCP server listens on
	// +kubebuilder:default=8080
	Port int32 `json:"port,omitempty"`
	
	// Replicas is the number of MCP server instances
	// +kubebuilder:default=1
	// +kubebuilder:validation:Minimum=1
	Replicas int32 `json:"replicas,omitempty"`
	
	// Transport specifies the MCP transport type
	// +kubebuilder:validation:Enum=stdio;http;streamable-http
	// +kubebuilder:default=streamable-http
	Transport string `json:"transport,omitempty"`
	
	// Config contains MCP server configuration
	Config map[string]string `json:"config,omitempty"`
	
	// Resources specifies resource requirements
	Resources *ResourceRequirements `json:"resources,omitempty"`
}

type ResourceRequirements struct {
	// CPU request and limit
	CPU string `json:"cpu,omitempty"`
	// Memory request and limit  
	Memory string `json:"memory,omitempty"`
}

// MCPServerStatus defines the observed state of MCPServer
type MCPServerStatus struct {
	// Phase represents the current phase of the MCPServer
	Phase string `json:"phase,omitempty"`
	
	// Conditions represent the latest available observations
	Conditions []metav1.Condition `json:"conditions,omitempty"`
	
	// ReadyReplicas is the number of ready replicas
	ReadyReplicas int32 `json:"readyReplicas,omitempty"`
	
	// Endpoint is the MCP server endpoint
	Endpoint string `json:"endpoint,omitempty"`
	
	// ObservedGeneration reflects the generation observed by the controller
	ObservedGeneration int64 `json:"observedGeneration,omitempty"`
}

//+kubebuilder:object:root=true
//+kubebuilder:subresource:status
//+kubebuilder:resource:shortName=mcps
//+kubebuilder:printcolumn:name="Phase",type=string,JSONPath=`.status.phase`
//+kubebuilder:printcolumn:name="Ready",type=integer,JSONPath=`.status.readyReplicas`
//+kubebuilder:printcolumn:name="Endpoint",type=string,JSONPath=`.status.endpoint`
//+kubebuilder:printcolumn:name="Age",type=date,JSONPath=`.metadata.creationTimestamp`

// MCPServer is the Schema for the mcpservers API
type MCPServer struct {
	metav1.TypeMeta   `json:",inline"`
	metav1.ObjectMeta `json:"metadata,omitempty"`

	Spec   MCPServerSpec   `json:"spec,omitempty"`
	Status MCPServerStatus `json:"status,omitempty"`
}

//+kubebuilder:object:root=true

// MCPServerList contains a list of MCPServer
type MCPServerList struct {
	metav1.TypeMeta `json:",inline"`
	metav1.ListMeta `json:"metadata,omitempty"`
	Items           []MCPServer `json:"items"`
}

func init() {
	SchemeBuilder.Register(&MCPServer{}, &MCPServerList{})
}

// Constants for MCPServer phases and conditions
const (
	MCPServerPhasePending = "Pending"
	MCPServerPhaseReady   = "Ready" 
	MCPServerPhaseFailed  = "Failed"
	
	MCPServerFinalizer = "mcp.example.com/finalizer"
)

// Condition types
const (
	ConditionReady           = "Ready"
	ConditionDeploymentReady = "DeploymentReady"
	ConditionServiceReady    = "ServiceReady"
)
EOF

echo "✅ Updated MCPServer types"
```{{exec}}

## Implement Deployment Creation

Now let's implement the deployment creation logic:

```bash
# Create deployment manager
cat > controllers/deployment.go << 'EOF'
package controllers

import (
	"context"
	"fmt"
	
	appsv1 "k8s.io/api/apps/v1"
	corev1 "k8s.io/api/core/v1"
	metav1 "k8s.io/apimachinery/pkg/apis/meta/v1"
	"k8s.io/apimachinery/pkg/util/intstr"
	"sigs.k8s.io/controller-runtime/pkg/controller/controllerutil"
	
	mcpv1alpha1 "github.com/example/mcp-operator/api/v1alpha1"
)

func (r *MCPServerReconciler) reconcileDeployment(ctx context.Context, mcpServer *mcpv1alpha1.MCPServer) (*appsv1.Deployment, error) {
	deployment := &appsv1.Deployment{
		ObjectMeta: metav1.ObjectMeta{
			Name:      mcpServer.Name,
			Namespace: mcpServer.Namespace,
		},
	}

	operationResult, err := controllerutil.CreateOrUpdate(ctx, r.Client, deployment, func() error {
		// Set owner reference
		if err := controllerutil.SetControllerReference(mcpServer, deployment, r.Scheme); err != nil {
			return err
		}

		// Configure deployment spec
		deployment.Spec = r.deploymentSpec(mcpServer)
		return nil
	})

	if err != nil {
		return nil, fmt.Errorf("failed to reconcile deployment: %w", err)
	}

	r.Log.Info("Deployment reconciled", "operation", operationResult, "deployment", deployment.Name)
	return deployment, nil
}

func (r *MCPServerReconciler) deploymentSpec(mcpServer *mcpv1alpha1.MCPServer) appsv1.DeploymentSpec {
	labels := r.labelsForMCPServer(mcpServer)
	replicas := mcpServer.Spec.Replicas
	if replicas == 0 {
		replicas = 1
	}

	return appsv1.DeploymentSpec{
		Replicas: &replicas,
		Selector: &metav1.LabelSelector{
			MatchLabels: labels,
		},
		Template: corev1.PodTemplateSpec{
			ObjectMeta: metav1.ObjectMeta{
				Labels: labels,
			},
			Spec: r.podSpec(mcpServer),
		},
	}
}

func (r *MCPServerReconciler) podSpec(mcpServer *mcpv1alpha1.MCPServer) corev1.PodSpec {
	port := mcpServer.Spec.Port
	if port == 0 {
		port = 8080
	}

	// Build environment variables from config
	envVars := []corev1.EnvVar{
		{Name: "MCP_TRANSPORT", Value: mcpServer.Spec.Transport},
		{Name: "MCP_PORT", Value: fmt.Sprintf("%d", port)},
	}
	
	for key, value := range mcpServer.Spec.Config {
		envVars = append(envVars, corev1.EnvVar{
			Name:  key,
			Value: value,
		})
	}

	// Resource requirements
	resources := corev1.ResourceRequirements{}
	if mcpServer.Spec.Resources != nil {
		if mcpServer.Spec.Resources.CPU != "" {
			resources.Requests = corev1.ResourceList{
				corev1.ResourceCPU: resource.MustParse(mcpServer.Spec.Resources.CPU),
			}
			resources.Limits = corev1.ResourceList{
				corev1.ResourceCPU: resource.MustParse(mcpServer.Spec.Resources.CPU),
			}
		}
		if mcpServer.Spec.Resources.Memory != "" {
			if resources.Requests == nil {
				resources.Requests = corev1.ResourceList{}
			}
			if resources.Limits == nil {
				resources.Limits = corev1.ResourceList{}
			}
			resources.Requests[corev1.ResourceMemory] = resource.MustParse(mcpServer.Spec.Resources.Memory)
			resources.Limits[corev1.ResourceMemory] = resource.MustParse(mcpServer.Spec.Resources.Memory)
		}
	}

	return corev1.PodSpec{
		Containers: []corev1.Container{
			{
				Name:  "mcp-server",
				Image: mcpServer.Spec.Image,
				Ports: []corev1.ContainerPort{
					{
						ContainerPort: port,
						Name:          "mcp",
						Protocol:      corev1.ProtocolTCP,
					},
				},
				Env: envVars,
				Resources: resources,
				LivenessProbe: &corev1.Probe{
					ProbeHandler: corev1.ProbeHandler{
						HTTPGet: &corev1.HTTPGetAction{
							Path: "/health",
							Port: intstr.FromInt(int(port)),
						},
					},
					InitialDelaySeconds: 30,
					PeriodSeconds:       10,
				},
				ReadinessProbe: &corev1.Probe{
					ProbeHandler: corev1.ProbeHandler{
						HTTPGet: &corev1.HTTPGetAction{
							Path: "/ready",
							Port: intstr.FromInt(int(port)),
						},
					},
					InitialDelaySeconds: 5,
					PeriodSeconds:       5,
				},
			},
		},
	}
}

func (r *MCPServerReconciler) labelsForMCPServer(mcpServer *mcpv1alpha1.MCPServer) map[string]string {
	return map[string]string{
		"app.kubernetes.io/name":       "mcp-server",
		"app.kubernetes.io/instance":   mcpServer.Name,
		"app.kubernetes.io/component":  "server",
		"app.kubernetes.io/managed-by": "mcp-operator",
	}
}
EOF

echo "✅ Created deployment management logic"
```{{exec}}

## Implement Service Creation

```bash
# Create service manager
cat > controllers/service.go << 'EOF'
package controllers

import (
	"context"
	"fmt"
	
	corev1 "k8s.io/api/core/v1"
	metav1 "k8s.io/apimachinery/pkg/apis/meta/v1"
	"k8s.io/apimachinery/pkg/util/intstr"
	"sigs.k8s.io/controller-runtime/pkg/controller/controllerutil"
	
	mcpv1alpha1 "github.com/example/mcp-operator/api/v1alpha1"
)

func (r *MCPServerReconciler) reconcileService(ctx context.Context, mcpServer *mcpv1alpha1.MCPServer) (*corev1.Service, error) {
	service := &corev1.Service{
		ObjectMeta: metav1.ObjectMeta{
			Name:      mcpServer.Name,
			Namespace: mcpServer.Namespace,
		},
	}

	operationResult, err := controllerutil.CreateOrUpdate(ctx, r.Client, service, func() error {
		// Set owner reference
		if err := controllerutil.SetControllerReference(mcpServer, service, r.Scheme); err != nil {
			return err
		}

		// Configure service spec
		service.Spec = r.serviceSpec(mcpServer)
		return nil
	})

	if err != nil {
		return nil, fmt.Errorf("failed to reconcile service: %w", err)
	}

	r.Log.Info("Service reconciled", "operation", operationResult, "service", service.Name)
	return service, nil
}

func (r *MCPServerReconciler) serviceSpec(mcpServer *mcpv1alpha1.MCPServer) corev1.ServiceSpec {
	port := mcpServer.Spec.Port
	if port == 0 {
		port = 8080
	}

	return corev1.ServiceSpec{
		Selector: r.labelsForMCPServer(mcpServer),
		Ports: []corev1.ServicePort{
			{
				Name:       "mcp",
				Port:       port,
				TargetPort: intstr.FromString("mcp"),
				Protocol:   corev1.ProtocolTCP,
			},
		},
		Type: corev1.ServiceTypeClusterIP,
	}
}
EOF

echo "✅ Created service management logic"
```{{exec}}

## Update Main Controller

```bash
# Update the main controller to use our deployment and service logic
cat > controllers/mcpserver_controller.go << 'EOF'
package controllers

import (
	"context"
	"fmt"
	"time"
	
	appsv1 "k8s.io/api/apps/v1"
	corev1 "k8s.io/api/core/v1"
	"k8s.io/apimachinery/pkg/api/errors"
	metav1 "k8s.io/apimachinery/pkg/apis/meta/v1"
	"k8s.io/apimachinery/pkg/runtime"
	ctrl "sigs.k8s.io/controller-runtime"
	"sigs.k8s.io/controller-runtime/pkg/client"
	"sigs.k8s.io/controller-runtime/pkg/controller/controllerutil"
	"sigs.k8s.io/controller-runtime/pkg/log"
	
	mcpv1alpha1 "github.com/example/mcp-operator/api/v1alpha1"
)

// MCPServerReconciler reconciles a MCPServer object
type MCPServerReconciler struct {
	client.Client
	Scheme *runtime.Scheme
}

//+kubebuilder:rbac:groups=mcp.example.com,resources=mcpservers,verbs=get;list;watch;create;update;patch;delete
//+kubebuilder:rbac:groups=mcp.example.com,resources=mcpservers/status,verbs=get;update;patch
//+kubebuilder:rbac:groups=mcp.example.com,resources=mcpservers/finalizers,verbs=update
//+kubebuilder:rbac:groups=apps,resources=deployments,verbs=get;list;watch;create;update;patch;delete
//+kubebuilder:rbac:groups="",resources=services,verbs=get;list;watch;create;update;patch;delete
//+kubebuilder:rbac:groups="",resources=events,verbs=create;patch

func (r *MCPServerReconciler) Reconcile(ctx context.Context, req ctrl.Request) (ctrl.Result, error) {
	logger := log.FromContext(ctx)

	// Fetch the MCPServer instance
	var mcpServer mcpv1alpha1.MCPServer
	if err := r.Get(ctx, req.NamespacedName, &mcpServer); err != nil {
		if errors.IsNotFound(err) {
			logger.Info("MCPServer not found, probably deleted")
			return ctrl.Result{}, nil
		}
		logger.Error(err, "Failed to get MCPServer")
		return ctrl.Result{}, err
	}

	// Handle finalizer logic
	if mcpServer.DeletionTimestamp == nil {
		// Add finalizer if not present
		if !controllerutil.ContainsFinalizer(&mcpServer, mcpv1alpha1.MCPServerFinalizer) {
			controllerutil.AddFinalizer(&mcpServer, mcpv1alpha1.MCPServerFinalizer)
			if err := r.Update(ctx, &mcpServer); err != nil {
				logger.Error(err, "Failed to add finalizer")
				return ctrl.Result{}, err
			}
			return ctrl.Result{}, nil
		}
	} else {
		// Handle deletion
		if controllerutil.ContainsFinalizer(&mcpServer, mcpv1alpha1.MCPServerFinalizer) {
			if err := r.cleanup(ctx, &mcpServer); err != nil {
				logger.Error(err, "Failed to cleanup resources")
				return ctrl.Result{}, err
			}
			
			controllerutil.RemoveFinalizer(&mcpServer, mcpv1alpha1.MCPServerFinalizer)
			if err := r.Update(ctx, &mcpServer); err != nil {
				logger.Error(err, "Failed to remove finalizer")
				return ctrl.Result{}, err
			}
		}
		return ctrl.Result{}, nil
	}

	// Reconcile Deployment
	deployment, err := r.reconcileDeployment(ctx, &mcpServer)
	if err != nil {
		logger.Error(err, "Failed to reconcile Deployment")
		r.updateStatus(ctx, &mcpServer, mcpv1alpha1.MCPServerPhaseFailed, "Failed to reconcile deployment")
		return ctrl.Result{}, err
	}

	// Reconcile Service
	service, err := r.reconcileService(ctx, &mcpServer)
	if err != nil {
		logger.Error(err, "Failed to reconcile Service")
		r.updateStatus(ctx, &mcpServer, mcpv1alpha1.MCPServerPhaseFailed, "Failed to reconcile service")
		return ctrl.Result{}, err
	}

	// Update status based on deployment readiness
	if deployment.Status.ReadyReplicas == *deployment.Spec.Replicas {
		endpoint := fmt.Sprintf("http://%s.%s.svc.cluster.local:%d", service.Name, service.Namespace, mcpServer.Spec.Port)
		r.updateStatus(ctx, &mcpServer, mcpv1alpha1.MCPServerPhaseReady, endpoint)
	} else {
		r.updateStatus(ctx, &mcpServer, mcpv1alpha1.MCPServerPhasePending, "Waiting for deployment to be ready")
		// Requeue to check again
		return ctrl.Result{RequeueAfter: time.Second * 10}, nil
	}

	return ctrl.Result{}, nil
}

func (r *MCPServerReconciler) cleanup(ctx context.Context, mcpServer *mcpv1alpha1.MCPServer) error {
	logger := log.FromContext(ctx)
	logger.Info("Cleaning up MCPServer resources")
	
	// Deployment and Service will be automatically deleted due to owner references
	// Any additional cleanup logic would go here
	
	return nil
}

func (r *MCPServerReconciler) updateStatus(ctx context.Context, mcpServer *mcpv1alpha1.MCPServer, phase, message string) error {
	mcpServer.Status.Phase = phase
	mcpServer.Status.ObservedGeneration = mcpServer.Generation
	
	// Update conditions
	condition := metav1.Condition{
		Type:    mcpv1alpha1.ConditionReady,
		Status:  metav1.ConditionFalse,
		Reason:  "NotReady",
		Message: message,
	}
	
	if phase == mcpv1alpha1.MCPServerPhaseReady {
		condition.Status = metav1.ConditionTrue
		condition.Reason = "Ready"
		mcpServer.Status.Endpoint = message // In ready case, message is endpoint
	}
	
	// Update or append condition
	found := false
	for i, c := range mcpServer.Status.Conditions {
		if c.Type == mcpv1alpha1.ConditionReady {
			mcpServer.Status.Conditions[i] = condition
			found = true
			break
		}
	}
	if !found {
		mcpServer.Status.Conditions = append(mcpServer.Status.Conditions, condition)
	}

	return r.Status().Update(ctx, mcpServer)
}

// SetupWithManager sets up the controller with the Manager.
func (r *MCPServerReconciler) SetupWithManager(mgr ctrl.Manager) error {
	return ctrl.NewControllerManagedBy(mgr).
		For(&mcpv1alpha1.MCPServer{}).
		Owns(&appsv1.Deployment{}).
		Owns(&corev1.Service{}).
		Complete(r)
}
EOF

echo "✅ Updated main controller logic"
```{{exec}}

## Generate and Build

```bash
# Generate CRD manifests and code
make generate
make manifests

# Build the operator
make build

echo "✅ MCPServer operator built successfully"
```{{exec}}

## Test Deployment

```bash
# Install CRDs
make install

# Create a sample MCPServer
cat > config/samples/mcp_v1alpha1_mcpserver.yaml << 'EOF'
apiVersion: mcp.example.com/v1alpha1
kind: MCPServer
metadata:
  name: example-mcpserver
spec:
  image: "node:18-alpine"
  port: 8080
  replicas: 1
  transport: "streamable-http"
  config:
    MCP_SERVER_TYPE: "kubernetes"
    KUBECONFIG: "/etc/kubeconfig/config"
  resources:
    cpu: "100m"
    memory: "128Mi"
EOF

echo "✅ Sample MCPServer created"
cat config/samples/mcp_v1alpha1_mcpserver.yaml
```{{exec}}

## Summary

```bash
echo "🎉 Deployment and Service Management Complete!"
echo ""
echo "✅ What we built:"
echo "  📦 MCPServer CRD with comprehensive spec"
echo "  🚀 Deployment reconciliation logic"
echo "  🌐 Service creation and management"
echo "  📊 Status reporting and conditions"
echo "  🧹 Finalizer-based cleanup"
echo "  🏷️  Proper labeling and ownership"
echo ""
echo "🔧 Key Features:"
echo "  - Configurable resources and replicas"
echo "  - Health checks and probes"
echo "  - Environment-based configuration"
echo "  - Owner reference cleanup"
echo "  - Comprehensive RBAC"
```{{exec}}

Perfect! Our operator can now create and manage Deployments and Services for MCP servers. In the final step, we'll cover testing and production considerations!
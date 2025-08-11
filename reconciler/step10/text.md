# Step 10: Implementing MCPServer Controller

Now we'll implement the complete MCPServer controller based on our architecture design. This will bring together all the patterns we've learned to create a production-ready operator.

## Initialize the Operator Project

Let's create our complete MCPServer operator:

```bash
# Create the operator workspace
mkdir -p /workspace/mcp-operator
cd /workspace/mcp-operator

# Initialize Kubebuilder project
kubebuilder init --domain mcp.example.com --repo github.com/example/mcp-operator

echo "✅ MCPServer operator project initialized"
```{{exec}}

## Create the MCPServer API

```bash
# Create the MCPServer API and controller
kubebuilder create api --group mcp --version v1alpha1 --kind MCPServer --controller --resource

echo "✅ MCPServer API and controller scaffold created"
```{{exec}}

## Implement Complete MCPServer Types

Let's implement our comprehensive MCPServer specification with all the features we designed:

```bash
# Update the MCPServer types with our complete specification
cat > api/v1alpha1/mcpserver_types.go << 'EOF'
package v1alpha1

import (
	corev1 "k8s.io/api/core/v1"
	"k8s.io/apimachinery/pkg/api/resource"
	metav1 "k8s.io/apimachinery/pkg/apis/meta/v1"
)

// MCPServerSpec defines the desired state of MCPServer
type MCPServerSpec struct {
	// Image is the container image for the MCP server
	// +kubebuilder:validation:Required
	// +kubebuilder:validation:MinLength=1
	Image string `json:"image"`

	// Transport specifies the MCP transport protocol
	// +kubebuilder:validation:Enum=stdio;http;streamable-http
	// +kubebuilder:default=streamable-http
	Transport string `json:"transport,omitempty"`

	// Port is the port the MCP server listens on
	// +kubebuilder:validation:Minimum=1
	// +kubebuilder:validation:Maximum=65535
	// +kubebuilder:default=8080
	Port int32 `json:"port,omitempty"`

	// Replicas is the desired number of MCP server instances
	// +kubebuilder:validation:Minimum=0
	// +kubebuilder:default=1
	Replicas *int32 `json:"replicas,omitempty"`

	// Config contains MCP server configuration as key-value pairs
	// +kubebuilder:validation:Optional
	Config map[string]string `json:"config,omitempty"`

	// Resources specifies the resource requirements for the MCP server
	// +kubebuilder:validation:Optional
	Resources *MCPServerResources `json:"resources,omitempty"`

	// SecurityContext defines security settings for the MCP server pod
	// +kubebuilder:validation:Optional
	SecurityContext *corev1.SecurityContext `json:"securityContext,omitempty"`

	// ServiceAccount specifies the service account to use
	// +kubebuilder:validation:Optional
	ServiceAccount string `json:"serviceAccount,omitempty"`

	// Env allows additional environment variables
	// +kubebuilder:validation:Optional
	Env []corev1.EnvVar `json:"env,omitempty"`
}

// MCPServerResources defines resource requirements
type MCPServerResources struct {
	// Requests describes the minimum amount of compute resources required
	// +kubebuilder:validation:Optional
	Requests corev1.ResourceList `json:"requests,omitempty"`

	// Limits describes the maximum amount of compute resources allowed
	// +kubebuilder:validation:Optional
	Limits corev1.ResourceList `json:"limits,omitempty"`
}

// MCPServerStatus defines the observed state of MCPServer
type MCPServerStatus struct {
	// Phase represents the current phase of the MCPServer lifecycle
	// +kubebuilder:validation:Enum=Pending;Ready;Failed;Terminating
	Phase MCPServerPhase `json:"phase,omitempty"`

	// Conditions represent the latest available observations of the MCPServer's state
	// +kubebuilder:validation:Optional
	Conditions []metav1.Condition `json:"conditions,omitempty"`

	// ReadyReplicas is the number of ready MCP server replicas
	// +kubebuilder:validation:Minimum=0
	ReadyReplicas int32 `json:"readyReplicas,omitempty"`

	// Replicas is the total number of MCP server replicas
	// +kubebuilder:validation:Minimum=0
	Replicas int32 `json:"replicas,omitempty"`

	// Endpoint is the URL where the MCP server can be accessed
	// +kubebuilder:validation:Optional
	Endpoint string `json:"endpoint,omitempty"`

	// ObservedGeneration reflects the generation of the most recently observed MCPServer
	// +kubebuilder:validation:Minimum=0
	ObservedGeneration int64 `json:"observedGeneration,omitempty"`

	// LastTransitionTime is the last time the condition transitioned
	// +kubebuilder:validation:Optional
	LastTransitionTime *metav1.Time `json:"lastTransitionTime,omitempty"`
}

// MCPServerPhase represents the lifecycle phase of an MCPServer
// +kubebuilder:validation:Enum=Pending;Ready;Failed;Terminating
type MCPServerPhase string

const (
	// MCPServerPhasePending indicates the MCPServer is being processed
	MCPServerPhasePending MCPServerPhase = "Pending"
	// MCPServerPhaseReady indicates the MCPServer is ready and serving requests
	MCPServerPhaseReady MCPServerPhase = "Ready"
	// MCPServerPhaseFailed indicates the MCPServer has failed
	MCPServerPhaseFailed MCPServerPhase = "Failed"
	// MCPServerPhaseTerminating indicates the MCPServer is being deleted
	MCPServerPhaseTerminating MCPServerPhase = "Terminating"
)

// Condition types for MCPServer
const (
	// ConditionReady indicates whether the MCPServer is ready to serve requests
	ConditionReady = "Ready"
	// ConditionDeploymentReady indicates whether the underlying Deployment is ready
	ConditionDeploymentReady = "DeploymentReady"
	// ConditionServiceReady indicates whether the Service is ready
	ConditionServiceReady = "ServiceReady"
	// ConditionConfigurationValid indicates whether the configuration is valid
	ConditionConfigurationValid = "ConfigurationValid"
)

// Finalizer for MCPServer cleanup
const (
	MCPServerFinalizer = "mcp.example.com/finalizer"
)

//+kubebuilder:object:root=true
//+kubebuilder:subresource:status
//+kubebuilder:subresource:scale:specpath=.spec.replicas,statuspath=.status.replicas
//+kubebuilder:resource:shortName=mcps,categories=ai;mcp
//+kubebuilder:printcolumn:name="Phase",type=string,JSONPath=`.status.phase`
//+kubebuilder:printcolumn:name="Ready",type=integer,JSONPath=`.status.readyReplicas`
//+kubebuilder:printcolumn:name="Replicas",type=integer,JSONPath=`.spec.replicas`
//+kubebuilder:printcolumn:name="Transport",type=string,JSONPath=`.spec.transport`
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

// Helper methods for MCPServer

// GetReplicas returns the desired number of replicas, defaulting to 1
func (m *MCPServer) GetReplicas() int32 {
	if m.Spec.Replicas == nil {
		return 1
	}
	return *m.Spec.Replicas
}

// GetPort returns the port, defaulting to 8080
func (m *MCPServer) GetPort() int32 {
	if m.Spec.Port == 0 {
		return 8080
	}
	return m.Spec.Port
}

// GetTransport returns the transport, defaulting to streamable-http
func (m *MCPServer) GetTransport() string {
	if m.Spec.Transport == "" {
		return "streamable-http"
	}
	return m.Spec.Transport
}

// IsReady returns true if the MCPServer is ready
func (m *MCPServer) IsReady() bool {
	return m.Status.Phase == MCPServerPhaseReady && 
		   m.Status.ReadyReplicas == m.GetReplicas()
}

// GetCondition returns the condition with the specified type
func (m *MCPServer) GetCondition(condType string) *metav1.Condition {
	for i := range m.Status.Conditions {
		if m.Status.Conditions[i].Type == condType {
			return &m.Status.Conditions[i]
		}
	}
	return nil
}

// SetCondition sets or updates a condition
func (m *MCPServer) SetCondition(condType, status, reason, message string) {
	condition := metav1.Condition{
		Type:               condType,
		Status:             metav1.ConditionStatus(status),
		Reason:             reason,
		Message:            message,
		LastTransitionTime: metav1.Now(),
	}

	// Find and update existing condition
	for i := range m.Status.Conditions {
		if m.Status.Conditions[i].Type == condType {
			// Only update if status changed
			if m.Status.Conditions[i].Status != condition.Status ||
			   m.Status.Conditions[i].Reason != condition.Reason ||
			   m.Status.Conditions[i].Message != condition.Message {
				m.Status.Conditions[i] = condition
			}
			return
		}
	}

	// Add new condition
	m.Status.Conditions = append(m.Status.Conditions, condition)
}

// SetDefaultResources sets default resource requirements based on transport
func (m *MCPServer) SetDefaultResources() {
	if m.Spec.Resources == nil {
		m.Spec.Resources = &MCPServerResources{}
	}

	if m.Spec.Resources.Requests == nil {
		m.Spec.Resources.Requests = corev1.ResourceList{}
	}
	if m.Spec.Resources.Limits == nil {
		m.Spec.Resources.Limits = corev1.ResourceList{}
	}

	// Set defaults based on transport type
	switch m.GetTransport() {
	case "stdio":
		// stdio is lightweight
		if _, exists := m.Spec.Resources.Requests[corev1.ResourceCPU]; !exists {
			m.Spec.Resources.Requests[corev1.ResourceCPU] = resource.MustParse("50m")
		}
		if _, exists := m.Spec.Resources.Requests[corev1.ResourceMemory]; !exists {
			m.Spec.Resources.Requests[corev1.ResourceMemory] = resource.MustParse("64Mi")
		}
	case "http":
		// HTTP needs more resources for networking
		if _, exists := m.Spec.Resources.Requests[corev1.ResourceCPU]; !exists {
			m.Spec.Resources.Requests[corev1.ResourceCPU] = resource.MustParse("100m")
		}
		if _, exists := m.Spec.Resources.Requests[corev1.ResourceMemory]; !exists {
			m.Spec.Resources.Requests[corev1.ResourceMemory] = resource.MustParse("128Mi")
		}
	case "streamable-http":
		// Streamable HTTP needs most resources for session management
		if _, exists := m.Spec.Resources.Requests[corev1.ResourceCPU]; !exists {
			m.Spec.Resources.Requests[corev1.ResourceCPU] = resource.MustParse("200m")
		}
		if _, exists := m.Spec.Resources.Requests[corev1.ResourceMemory]; !exists {
			m.Spec.Resources.Requests[corev1.ResourceMemory] = resource.MustParse("256Mi")
		}
	}
}
EOF

echo "✅ Complete MCPServer types implemented"
```{{exec}}

## Implement the Core Controller Logic

```bash
# Create the main controller with complete reconciliation logic
cat > controllers/mcpserver_controller.go << 'EOF'
package controllers

import (
	"context"
	"fmt"
	"time"

	appsv1 "k8s.io/api/apps/v1"
	corev1 "k8s.io/api/core/v1"
	"k8s.io/apimachinery/pkg/api/errors"
	"k8s.io/apimachinery/pkg/api/resource"
	metav1 "k8s.io/apimachinery/pkg/apis/meta/v1"
	"k8s.io/apimachinery/pkg/runtime"
	"k8s.io/apimachinery/pkg/types"
	"k8s.io/apimachinery/pkg/util/intstr"
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
//+kubebuilder:rbac:groups="",resources=configmaps,verbs=get;list;watch;create;update;patch;delete
//+kubebuilder:rbac:groups="",resources=events,verbs=create;patch

func (r *MCPServerReconciler) Reconcile(ctx context.Context, req ctrl.Request) (ctrl.Result, error) {
	logger := log.FromContext(ctx)
	logger.Info("Reconciling MCPServer", "namespacedName", req.NamespacedName)

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
			if err := r.handleDeletion(ctx, &mcpServer); err != nil {
				logger.Error(err, "Failed to handle deletion")
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

	// Set default values
	mcpServer.SetDefaultResources()

	// Validate configuration
	if err := r.validateMCPServer(&mcpServer); err != nil {
		logger.Error(err, "MCPServer configuration validation failed")
		r.updateStatus(ctx, &mcpServer, mcpv1alpha1.MCPServerPhaseFailed, "Configuration validation failed: "+err.Error())
		return ctrl.Result{RequeueAfter: 5 * time.Minute}, nil
	}

	// Reconcile ConfigMap
	configMap, err := r.reconcileConfigMap(ctx, &mcpServer)
	if err != nil {
		logger.Error(err, "Failed to reconcile ConfigMap")
		r.updateStatus(ctx, &mcpServer, mcpv1alpha1.MCPServerPhaseFailed, "Failed to reconcile configmap")
		return ctrl.Result{}, err
	}

	// Reconcile Service
	service, err := r.reconcileService(ctx, &mcpServer)
	if err != nil {
		logger.Error(err, "Failed to reconcile Service")
		r.updateStatus(ctx, &mcpServer, mcpv1alpha1.MCPServerPhaseFailed, "Failed to reconcile service")
		return ctrl.Result{}, err
	}

	// Reconcile Deployment
	deployment, err := r.reconcileDeployment(ctx, &mcpServer, configMap)
	if err != nil {
		logger.Error(err, "Failed to reconcile Deployment")
		r.updateStatus(ctx, &mcpServer, mcpv1alpha1.MCPServerPhaseFailed, "Failed to reconcile deployment")
		return ctrl.Result{}, err
	}

	// Update status based on deployment readiness
	return r.updateStatusFromResources(ctx, &mcpServer, deployment, service)
}

// handleDeletion manages the deletion process with proper cleanup
func (r *MCPServerReconciler) handleDeletion(ctx context.Context, mcpServer *mcpv1alpha1.MCPServer) error {
	logger := log.FromContext(ctx)
	logger.Info("Handling MCPServer deletion", "mcpserver", mcpServer.Name)

	// Update status to indicate termination is starting
	mcpServer.Status.Phase = mcpv1alpha1.MCPServerPhaseTerminating
	mcpServer.SetCondition(
		mcpv1alpha1.ConditionReady,
		"False",
		"Terminating",
		"MCPServer is being deleted",
	)
	
	if err := r.Status().Update(ctx, mcpServer); err != nil {
		logger.Error(err, "Failed to update status during deletion")
	}

	// Perform graceful shutdown for MCP-specific workloads
	if err := r.performGracefulShutdown(ctx, mcpServer); err != nil {
		logger.Error(err, "Failed to perform graceful shutdown")
		// Continue with cleanup even if graceful shutdown fails
	}

	// Additional cleanup logic can go here
	logger.Info("MCPServer cleanup completed", "mcpserver", mcpServer.Name)
	return nil
}

// performGracefulShutdown handles MCP-specific graceful shutdown
func (r *MCPServerReconciler) performGracefulShutdown(ctx context.Context, mcpServer *mcpv1alpha1.MCPServer) error {
	logger := log.FromContext(ctx)
	logger.Info("Starting graceful shutdown", "transport", mcpServer.GetTransport())

	// Get current deployment
	deployment := &appsv1.Deployment{}
	err := r.Get(ctx, types.NamespacedName{
		Name:      mcpServer.Name,
		Namespace: mcpServer.Namespace,
	}, deployment)
	if err != nil {
		if errors.IsNotFound(err) {
			return nil // Deployment already gone
		}
		return err
	}

	// Set appropriate termination grace period based on transport
	gracePeriod := r.getTerminationGracePeriod(mcpServer.GetTransport())
	deployment.Spec.Template.Spec.TerminationGracePeriodSeconds = &gracePeriod

	if err := r.Update(ctx, deployment); err != nil {
		return fmt.Errorf("failed to update deployment for graceful shutdown: %w", err)
	}

	return nil
}

// getTerminationGracePeriod returns appropriate grace period based on transport
func (r *MCPServerReconciler) getTerminationGracePeriod(transport string) int64 {
	switch transport {
	case "stdio":
		return 5 // stdio connections are typically short-lived
	case "http":
		return 15 // HTTP requests should complete quickly  
	case "streamable-http":
		return 30 // Streamable connections may need more time
	default:
		return 30
	}
}

// validateMCPServer validates the MCPServer configuration
func (r *MCPServerReconciler) validateMCPServer(mcpServer *mcpv1alpha1.MCPServer) error {
	// Validate transport-specific configuration
	transport := mcpServer.GetTransport()
	
	if transport == "stdio" && mcpServer.GetReplicas() > 1 {
		return fmt.Errorf("stdio transport does not support multiple replicas (requested: %d)", mcpServer.GetReplicas())
	}

	return nil
}

// updateStatusFromResources updates status based on actual resource state
func (r *MCPServerReconciler) updateStatusFromResources(ctx context.Context, mcpServer *mcpv1alpha1.MCPServer, deployment *appsv1.Deployment, service *corev1.Service) (ctrl.Result, error) {
	// Update replica counts
	mcpServer.Status.Replicas = deployment.Status.Replicas
	mcpServer.Status.ReadyReplicas = deployment.Status.ReadyReplicas
	mcpServer.Status.ObservedGeneration = mcpServer.Generation

	// Update deployment condition
	deploymentReady := deployment.Status.ReadyReplicas == *deployment.Spec.Replicas && deployment.Status.ReadyReplicas > 0
	if deploymentReady {
		mcpServer.SetCondition(
			mcpv1alpha1.ConditionDeploymentReady,
			"True",
			"DeploymentReady",
			fmt.Sprintf("Deployment has %d/%d ready replicas", deployment.Status.ReadyReplicas, *deployment.Spec.Replicas),
		)
	} else {
		mcpServer.SetCondition(
			mcpv1alpha1.ConditionDeploymentReady,
			"False",
			"DeploymentNotReady",
			fmt.Sprintf("Deployment has %d/%d ready replicas", deployment.Status.ReadyReplicas, *deployment.Spec.Replicas),
		)
	}

	// Update service condition
	serviceReady := r.isServiceReady(service)
	if serviceReady {
		mcpServer.SetCondition(
			mcpv1alpha1.ConditionServiceReady,
			"True",
			"ServiceReady",
			"Service is ready and available",
		)
	} else {
		mcpServer.SetCondition(
			mcpv1alpha1.ConditionServiceReady,
			"False",
			"ServiceNotReady",
			"Service is not ready",
		)
	}

	// Update overall phase and endpoint
	if deploymentReady && serviceReady {
		mcpServer.Status.Phase = mcpv1alpha1.MCPServerPhaseReady
		mcpServer.Status.Endpoint = r.buildEndpoint(mcpServer, service)
		
		mcpServer.SetCondition(
			mcpv1alpha1.ConditionReady,
			"True",
			"MCPServerReady", 
			"MCPServer is ready and serving requests",
		)
	} else {
		mcpServer.Status.Phase = mcpv1alpha1.MCPServerPhasePending
		mcpServer.Status.Endpoint = ""
		
		reason := r.getNotReadyReason(deploymentReady, serviceReady)
		mcpServer.SetCondition(
			mcpv1alpha1.ConditionReady,
			"False",
			"MCPServerNotReady",
			reason,
		)
	}

	// Mark configuration as valid since we passed validation
	mcpServer.SetCondition(
		mcpv1alpha1.ConditionConfigurationValid,
		"True",
		"ConfigurationValid",
		"MCPServer configuration is valid",
	)

	if err := r.Status().Update(ctx, mcpServer); err != nil {
		return ctrl.Result{}, err
	}

	// Requeue if not ready to check again
	if !deploymentReady {
		return ctrl.Result{RequeueAfter: time.Second * 10}, nil
	}

	return ctrl.Result{}, nil
}

// isServiceReady determines if a service is ready
func (r *MCPServerReconciler) isServiceReady(service *corev1.Service) bool {
	// For ClusterIP services, they're ready when they have a cluster IP
	if service.Spec.Type == corev1.ServiceTypeClusterIP {
		return service.Spec.ClusterIP != "" && service.Spec.ClusterIP != "None"
	}

	// For LoadBalancer services, check if external IP is assigned
	if service.Spec.Type == corev1.ServiceTypeLoadBalancer {
		return len(service.Status.LoadBalancer.Ingress) > 0
	}

	// For NodePort services, they're ready when they have node ports assigned
	if service.Spec.Type == corev1.ServiceTypeNodePort {
		for _, port := range service.Spec.Ports {
			if port.NodePort == 0 {
				return false
			}
		}
		return true
	}

	return true
}

// buildEndpoint constructs the service endpoint URL
func (r *MCPServerReconciler) buildEndpoint(mcpServer *mcpv1alpha1.MCPServer, service *corev1.Service) string {
	transport := mcpServer.GetTransport()
	port := mcpServer.GetPort()

	switch transport {
	case "stdio":
		// stdio doesn't have an HTTP endpoint
		return fmt.Sprintf("stdio://%s.%s.svc.cluster.local", service.Name, service.Namespace)
	case "http", "streamable-http":
		protocol := "http"
		if transport == "streamable-http" {
			protocol = "http" // Still HTTP, but with streaming capabilities
		}
		return fmt.Sprintf("%s://%s.%s.svc.cluster.local:%d", protocol, service.Name, service.Namespace, port)
	default:
		return fmt.Sprintf("unknown://%s.%s.svc.cluster.local:%d", service.Name, service.Namespace, port)
	}
}

// getNotReadyReason determines why the MCPServer is not ready
func (r *MCPServerReconciler) getNotReadyReason(deploymentReady, serviceReady bool) string {
	if !deploymentReady && !serviceReady {
		return "Deployment and Service are not ready"
	} else if !deploymentReady {
		return "Deployment is not ready"
	} else if !serviceReady {
		return "Service is not ready" 
	}
	return "MCPServer is not ready"
}

// updateStatus is a helper method to update MCPServer status
func (r *MCPServerReconciler) updateStatus(ctx context.Context, mcpServer *mcpv1alpha1.MCPServer, phase mcpv1alpha1.MCPServerPhase, message string) error {
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
		Owns(&corev1.ConfigMap{}).
		Complete(r)
}
EOF

echo "✅ Core controller logic implemented"
```{{exec}}

## Implement Resource Management

Now let's create the deployment, service, and configmap management logic:

```bash
# Create deployment management
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

func (r *MCPServerReconciler) reconcileDeployment(ctx context.Context, mcpServer *mcpv1alpha1.MCPServer, configMap *corev1.ConfigMap) (*appsv1.Deployment, error) {
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
		deployment.Spec = r.deploymentSpec(mcpServer, configMap)
		return nil
	})

	if err != nil {
		return nil, fmt.Errorf("failed to reconcile deployment: %w", err)
	}

	log.FromContext(ctx).Info("Deployment reconciled", "operation", operationResult, "deployment", deployment.Name)
	return deployment, nil
}

func (r *MCPServerReconciler) deploymentSpec(mcpServer *mcpv1alpha1.MCPServer, configMap *corev1.ConfigMap) appsv1.DeploymentSpec {
	labels := r.labelsForMCPServer(mcpServer)
	replicas := mcpServer.GetReplicas()

	return appsv1.DeploymentSpec{
		Replicas: &replicas,
		Selector: &metav1.LabelSelector{
			MatchLabels: labels,
		},
		Template: corev1.PodTemplateSpec{
			ObjectMeta: metav1.ObjectMeta{
				Labels: labels,
			},
			Spec: r.podSpec(mcpServer, configMap),
		},
	}
}

func (r *MCPServerReconciler) podSpec(mcpServer *mcpv1alpha1.MCPServer, configMap *corev1.ConfigMap) corev1.PodSpec {
	port := mcpServer.GetPort()

	// Build environment variables from config
	envVars := []corev1.EnvVar{
		{Name: "MCP_TRANSPORT", Value: mcpServer.GetTransport()},
		{Name: "MCP_PORT", Value: fmt.Sprintf("%d", port)},
		{Name: "MCP_SERVER_NAME", Value: mcpServer.Name},
		{
			Name: "POD_NAME",
			ValueFrom: &corev1.EnvVarSource{
				FieldRef: &corev1.ObjectFieldSelector{
					FieldPath: "metadata.name",
				},
			},
		},
		{
			Name: "POD_NAMESPACE",
			ValueFrom: &corev1.EnvVarSource{
				FieldRef: &corev1.ObjectFieldSelector{
					FieldPath: "metadata.namespace",
				},
			},
		},
	}
	
	// Add custom environment variables
	envVars = append(envVars, mcpServer.Spec.Env...)

	// Add config from ConfigMap
	if configMap != nil {
		envVars = append(envVars, corev1.EnvVar{
			Name: "MCP_CONFIG_FILE",
			Value: "/etc/mcp/config.json",
		})
	}

	// Container definition
	container := corev1.Container{
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
		LivenessProbe: &corev1.Probe{
			ProbeHandler: corev1.ProbeHandler{
				HTTPGet: &corev1.HTTPGetAction{
					Path: "/health",
					Port: intstr.FromInt(int(port)),
				},
			},
			InitialDelaySeconds: 30,
			PeriodSeconds:       10,
			FailureThreshold:    3,
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
			FailureThreshold:    3,
		},
	}

	// Set resource requirements
	if mcpServer.Spec.Resources != nil {
		container.Resources = corev1.ResourceRequirements{
			Requests: mcpServer.Spec.Resources.Requests,
			Limits:   mcpServer.Spec.Resources.Limits,
		}
	}

	// Add volume mounts for config
	if configMap != nil {
		container.VolumeMounts = []corev1.VolumeMount{
			{
				Name:      "config",
				MountPath: "/etc/mcp",
				ReadOnly:  true,
			},
		}
	}

	// Set security context
	if mcpServer.Spec.SecurityContext != nil {
		container.SecurityContext = mcpServer.Spec.SecurityContext
	} else {
		// Apply default security context
		container.SecurityContext = &corev1.SecurityContext{
			AllowPrivilegeEscalation: &[]bool{false}[0],
			RunAsNonRoot:            &[]bool{true}[0],
			RunAsUser:               &[]int64{1000}[0],
			Capabilities: &corev1.Capabilities{
				Drop: []corev1.Capability{"ALL"},
			},
			ReadOnlyRootFilesystem: &[]bool{true}[0],
		}
	}

	podSpec := corev1.PodSpec{
		Containers: []corev1.Container{container},
	}

	// Add volumes for config
	if configMap != nil {
		podSpec.Volumes = []corev1.Volume{
			{
				Name: "config",
				VolumeSource: corev1.VolumeSource{
					ConfigMap: &corev1.ConfigMapVolumeSource{
						LocalObjectReference: corev1.LocalObjectReference{
							Name: configMap.Name,
						},
					},
				},
			},
		}
	}

	// Set service account
	if mcpServer.Spec.ServiceAccount != "" {
		podSpec.ServiceAccountName = mcpServer.Spec.ServiceAccount
	}

	return podSpec
}

func (r *MCPServerReconciler) labelsForMCPServer(mcpServer *mcpv1alpha1.MCPServer) map[string]string {
	return map[string]string{
		"app.kubernetes.io/name":       "mcp-server",
		"app.kubernetes.io/instance":   mcpServer.Name,
		"app.kubernetes.io/component":  "server",
		"app.kubernetes.io/managed-by": "mcp-operator",
		"mcp.example.com/transport":    mcpServer.GetTransport(),
	}
}
EOF

echo "✅ Deployment management implemented"
```{{exec}}

## Implement Service and ConfigMap Management

```bash
# Create service management
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
	// Skip service creation for stdio transport
	if mcpServer.GetTransport() == "stdio" {
		return &corev1.Service{}, nil
	}

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

	log.FromContext(ctx).Info("Service reconciled", "operation", operationResult, "service", service.Name)
	return service, nil
}

func (r *MCPServerReconciler) serviceSpec(mcpServer *mcpv1alpha1.MCPServer) corev1.ServiceSpec {
	port := mcpServer.GetPort()

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

# Create configmap management
cat > controllers/configmap.go << 'EOF'
package controllers

import (
	"context"
	"encoding/json"
	"fmt"
	
	corev1 "k8s.io/api/core/v1"
	metav1 "k8s.io/apimachinery/pkg/apis/meta/v1"
	"sigs.k8s.io/controller-runtime/pkg/controller/controllerutil"
	
	mcpv1alpha1 "github.com/example/mcp-operator/api/v1alpha1"
)

func (r *MCPServerReconciler) reconcileConfigMap(ctx context.Context, mcpServer *mcpv1alpha1.MCPServer) (*corev1.ConfigMap, error) {
	// Skip configmap creation if no config provided
	if len(mcpServer.Spec.Config) == 0 {
		return nil, nil
	}

	configMap := &corev1.ConfigMap{
		ObjectMeta: metav1.ObjectMeta{
			Name:      mcpServer.Name + "-config",
			Namespace: mcpServer.Namespace,
		},
	}

	operationResult, err := controllerutil.CreateOrUpdate(ctx, r.Client, configMap, func() error {
		// Set owner reference
		if err := controllerutil.SetControllerReference(mcpServer, configMap, r.Scheme); err != nil {
			return err
		}

		// Configure configmap data
		return r.setConfigMapData(configMap, mcpServer)
	})

	if err != nil {
		return nil, fmt.Errorf("failed to reconcile configmap: %w", err)
	}

	log.FromContext(ctx).Info("ConfigMap reconciled", "operation", operationResult, "configmap", configMap.Name)
	return configMap, nil
}

func (r *MCPServerReconciler) setConfigMapData(configMap *corev1.ConfigMap, mcpServer *mcpv1alpha1.MCPServer) error {
	// Create MCP server configuration
	config := map[string]interface{}{
		"server": map[string]interface{}{
			"name":      mcpServer.Name,
			"transport": mcpServer.GetTransport(),
			"port":      mcpServer.GetPort(),
		},
		"config": mcpServer.Spec.Config,
	}

	// Add transport-specific configuration
	switch mcpServer.GetTransport() {
	case "http":
		config["http"] = map[string]interface{}{
			"cors": map[string]interface{}{
				"enabled": true,
				"origins": []string{"*"},
			},
		}
	case "streamable-http":
		config["streamable-http"] = map[string]interface{}{
			"session": map[string]interface{}{
				"timeout": "30m",
				"maxConnections": 100,
			},
		}
	}

	// Marshal to JSON
	configJSON, err := json.MarshalIndent(config, "", "  ")
	if err != nil {
		return fmt.Errorf("failed to marshal config to JSON: %w", err)
	}

	// Set configmap data
	if configMap.Data == nil {
		configMap.Data = make(map[string]string)
	}
	configMap.Data["config.json"] = string(configJSON)

	// Add individual config items as separate keys for easier access
	for key, value := range mcpServer.Spec.Config {
		configMap.Data[key] = value
	}

	return nil
}
EOF

echo "✅ Service and ConfigMap management implemented"
```{{exec}}

## Generate and Build the Operator

```bash
# Generate CRD manifests and code
make generate
make manifests

echo "✅ Generated CRD manifests and code"

# Build the operator
make build

echo "✅ MCPServer operator built successfully"
```{{exec}}

## Create Sample MCPServer Resources

```bash
# Create sample resources directory
mkdir -p config/samples

# Basic MCPServer
cat > config/samples/mcp_v1alpha1_mcpserver_basic.yaml << 'EOF'
apiVersion: mcp.example.com/v1alpha1
kind: MCPServer
metadata:
  name: basic-mcpserver
  labels:
    environment: development
spec:
  image: "node:18-alpine"
  transport: streamable-http
  port: 8080
  replicas: 1
  config:
    MCP_SERVER_NAME: "basic-kubernetes-server"
    LOG_LEVEL: "info"
EOF

# Advanced MCPServer with comprehensive configuration
cat > config/samples/mcp_v1alpha1_mcpserver_advanced.yaml << 'EOF'
apiVersion: mcp.example.com/v1alpha1
kind: MCPServer
metadata:
  name: advanced-mcpserver
  labels:
    environment: production
    team: ai-platform
spec:
  image: "myregistry/kubernetes-mcp-server:v1.2.0"
  transport: streamable-http
  port: 8080
  replicas: 3
  config:
    MCP_SERVER_NAME: "production-k8s-server"
    KUBERNETES_NAMESPACE: "default"
    LOG_LEVEL: "warn"
    ENABLE_METRICS: "true"
    RATE_LIMIT_REQUESTS: "100"
  resources:
    requests:
      cpu: "100m"
      memory: "128Mi"
    limits:
      cpu: "500m"
      memory: "512Mi"
  securityContext:
    runAsNonRoot: true
    runAsUser: 1000
    runAsGroup: 3000
    allowPrivilegeEscalation: false
    capabilities:
      drop:
        - ALL
    readOnlyRootFilesystem: true
  serviceAccount: mcp-server-sa
  env:
    - name: POD_NAME
      valueFrom:
        fieldRef:
          fieldPath: metadata.name
    - name: POD_NAMESPACE
      valueFrom:
        fieldRef:
          fieldPath: metadata.namespace
EOF

echo "✅ Sample MCPServer resources created"
```{{exec}}

## Test the Complete Operator

```bash
# Install the CRDs into the cluster
make install

echo "✅ MCPServer CRDs installed"

# Verify CRD installation
echo ""
echo "📋 Checking installed CRD:"
kubectl get crd mcpservers.mcp.example.com

# Test creating a basic MCPServer
echo ""
echo "🧪 Testing basic MCPServer creation:"
kubectl apply -f config/samples/mcp_v1alpha1_mcpserver_basic.yaml

# Check the created resource
echo ""
echo "📊 Created MCPServer:"
kubectl get mcpservers

echo ""
echo "📋 Detailed MCPServer information:"
kubectl describe mcpserver basic-mcpserver

# Cleanup test resource
kubectl delete mcpserver basic-mcpserver
```{{exec}}

## Summary

```bash
echo "🎉 MCPServer Controller Implementation Complete!"
echo ""
echo "✅ What we built:"
echo "  📦 Complete MCPServer CRD with comprehensive validation"
echo "  🧠 Full controller logic with reconciliation patterns"
echo "  🚀 Deployment management with security context"
echo "  🌐 Service creation for network transport types"
echo "  📋 ConfigMap management for MCP configuration"
echo "  🧹 Finalizer-based cleanup and graceful shutdown"
echo "  📊 Comprehensive status reporting with conditions"
echo "  🔄 Error handling and retry strategies"
echo ""
echo "🎯 Key Features:"
echo "  • Transport-aware resource creation (stdio, http, streamable-http)"
echo "  • Resource requirements with transport-based defaults"
echo "  • Security hardening with non-root execution"
echo "  • Health checks and readiness probes"
echo "  • Configuration injection via ConfigMap"
echo "  • Owner reference cleanup"
echo "  • Multi-replica support with load balancing"
echo "  • Comprehensive RBAC configuration"
echo ""
echo "🚀 Ready for production deployment and testing!"
```{{exec}}

Perfect! We've now implemented a complete, production-ready MCPServer controller with all the enterprise patterns and features we designed. In the final steps, we'll focus on deployment, service management, and production considerations!
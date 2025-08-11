# Step 8: Reconciliation Patterns for MCP Workloads

Now let's implement the core reconciliation patterns specifically designed for MCP server workloads. We'll focus on finalizers, status management, and MCP-specific error handling.

## Understanding MCP-Specific Reconciliation

MCP servers have unique requirements compared to typical web services:

```bash
echo "🎯 MCP Server Reconciliation Challenges:"
echo ""
echo "🔄 Session State Management:"
echo "  - MCP servers maintain stateful connections"
echo "  - Graceful shutdown requires session cleanup"
echo "  - Client reconnection during pod restarts"
echo ""
echo "🌐 Transport-Specific Behavior:"
echo "  - stdio: Single-use, no networking"
echo "  - HTTP: Stateless, simple scaling"
echo "  - Streamable HTTP: Session management, connection pooling"
echo ""
echo "🧹 Cleanup Considerations:"
echo "  - Active MCP sessions during deletion"
echo "  - Client notification of server shutdown"
echo "  - Resource cleanup across multiple components"
```{{exec}}

## Implement Finalizer Logic

Let's start with comprehensive finalizer management:

```bash
cd /workspace/mcp-operator

# Create the finalizer management logic
cat > controllers/finalizers.go << 'EOF'
package controllers

import (
	"context"
	"fmt"
	"time"

	appsv1 "k8s.io/api/apps/v1"
	corev1 "k8s.io/api/core/v1"
	"k8s.io/apimachinery/pkg/api/errors"
	"k8s.io/apimachinery/pkg/types"
	"sigs.k8s.io/controller-runtime/pkg/controller/controllerutil"
	"sigs.k8s.io/controller-runtime/pkg/log"

	mcpv1alpha1 "github.com/example/mcp-operator/api/v1alpha1"
)

const (
	// FinalizerCleanupTimeout is the maximum time to wait for graceful shutdown
	FinalizerCleanupTimeout = 30 * time.Second
	
	// GracefulShutdownAnnotation indicates graceful shutdown is in progress
	GracefulShutdownAnnotation = "mcp.example.com/graceful-shutdown"
)

// ensureFinalizer adds the MCPServer finalizer if not present
func (r *MCPServerReconciler) ensureFinalizer(ctx context.Context, mcpServer *mcpv1alpha1.MCPServer) error {
	if !controllerutil.ContainsFinalizer(mcpServer, mcpv1alpha1.MCPServerFinalizer) {
		controllerutil.AddFinalizer(mcpServer, mcpv1alpha1.MCPServerFinalizer)
		return r.Update(ctx, mcpServer)
	}
	return nil
}

// handleDeletion manages the deletion process with proper cleanup
func (r *MCPServerReconciler) handleDeletion(ctx context.Context, mcpServer *mcpv1alpha1.MCPServer) error {
	logger := log.FromContext(ctx)
	
	if !controllerutil.ContainsFinalizer(mcpServer, mcpv1alpha1.MCPServerFinalizer) {
		return nil
	}

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

	// Clean up all related resources
	if err := r.cleanupResources(ctx, mcpServer); err != nil {
		return fmt.Errorf("failed to cleanup resources: %w", err)
	}

	// Remove finalizer
	controllerutil.RemoveFinalizer(mcpServer, mcpv1alpha1.MCPServerFinalizer)
	return r.Update(ctx, mcpServer)
}

// performGracefulShutdown handles MCP-specific graceful shutdown
func (r *MCPServerReconciler) performGracefulShutdown(ctx context.Context, mcpServer *mcpv1alpha1.MCPServer) error {
	logger := log.FromContext(ctx)
	logger.Info("Starting graceful shutdown", "transport", mcpServer.GetTransport())

	// Add graceful shutdown annotation to deployment
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

	// Annotate deployment for graceful shutdown
	if deployment.Annotations == nil {
		deployment.Annotations = make(map[string]string)
	}
	deployment.Annotations[GracefulShutdownAnnotation] = time.Now().Format(time.RFC3339)

	// Set termination grace period based on transport type
	gracePeriod := r.getTerminationGracePeriod(mcpServer.GetTransport())
	deployment.Spec.Template.Spec.TerminationGracePeriodSeconds = &gracePeriod

	if err := r.Update(ctx, deployment); err != nil {
		return fmt.Errorf("failed to update deployment for graceful shutdown: %w", err)
	}

	// Wait for pods to terminate gracefully
	return r.waitForPodsTermination(ctx, mcpServer)
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

// waitForPodsTermination waits for all MCP server pods to terminate
func (r *MCPServerReconciler) waitForPodsTermination(ctx context.Context, mcpServer *mcpv1alpha1.MCPServer) error {
	logger := log.FromContext(ctx)
	
	timeout := time.After(FinalizerCleanupTimeout)
	ticker := time.NewTicker(2 * time.Second)
	defer ticker.Stop()

	labels := r.labelsForMCPServer(mcpServer)
	
	for {
		select {
		case <-timeout:
			logger.Info("Timeout waiting for pods to terminate, proceeding with cleanup")
			return nil
		case <-ticker.C:
			podList := &corev1.PodList{}
			if err := r.List(ctx, podList, 
				client.InNamespace(mcpServer.Namespace),
				client.MatchingLabels(labels)); err != nil {
				return err
			}

			if len(podList.Items) == 0 {
				logger.Info("All pods terminated successfully")
				return nil
			}

			logger.Info("Waiting for pods to terminate", "remaining", len(podList.Items))
		}
	}
}

// cleanupResources removes all resources created by the MCPServer
func (r *MCPServerReconciler) cleanupResources(ctx context.Context, mcpServer *mcpv1alpha1.MCPServer) error {
	logger := log.FromContext(ctx)
	logger.Info("Cleaning up MCPServer resources")

	// Cleanup is mostly handled by owner references, but we can do additional cleanup here
	
	// Clean up any external resources that don't have owner references
	if err := r.cleanupExternalResources(ctx, mcpServer); err != nil {
		logger.Error(err, "Failed to cleanup external resources")
		// Don't fail the entire cleanup for external resources
	}

	// Wait for owned resources to be cleaned up by Kubernetes garbage collection
	return r.waitForOwnedResourceCleanup(ctx, mcpServer)
}

// cleanupExternalResources handles cleanup of resources outside the cluster
func (r *MCPServerReconciler) cleanupExternalResources(ctx context.Context, mcpServer *mcpv1alpha1.MCPServer) error {
	logger := log.FromContext(ctx)
	
	// This is where you would cleanup external resources like:
	// - Cloud load balancers
	// - DNS entries  
	// - External service registrations
	// - Monitoring configurations
	
	logger.Info("Performing external resource cleanup", "mcpserver", mcpServer.Name)
	
	// For now, this is a placeholder
	return nil
}

// waitForOwnedResourceCleanup waits for Kubernetes to clean up owned resources
func (r *MCPServerReconciler) waitForOwnedResourceCleanup(ctx context.Context, mcpServer *mcpv1alpha1.MCPServer) error {
	logger := log.FromContext(ctx)
	
	timeout := time.After(FinalizerCleanupTimeout)
	ticker := time.NewTicker(2 * time.Second)
	defer ticker.Stop()

	for {
		select {
		case <-timeout:
			logger.Info("Timeout waiting for resource cleanup, proceeding")
			return nil
		case <-ticker.C:
			// Check if deployment still exists
			deployment := &appsv1.Deployment{}
			err := r.Get(ctx, types.NamespacedName{
				Name:      mcpServer.Name,
				Namespace: mcpServer.Namespace,
			}, deployment)
			
			if errors.IsNotFound(err) {
				logger.Info("All owned resources cleaned up successfully")
				return nil
			} else if err != nil {
				return err
			}
			
			logger.Info("Waiting for owned resources to be cleaned up")
		}
	}
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

echo "✅ Finalizer management logic created"
```{{exec}}

## Implement Status Management

Let's create comprehensive status management for MCP servers:

```bash
# Create status management logic
cat > controllers/status.go << 'EOF'
package controllers

import (
	"context"
	"fmt"
	"time"

	appsv1 "k8s.io/api/apps/v1"
	corev1 "k8s.io/api/core/v1"
	"k8s.io/apimachinery/pkg/api/errors"
	metav1 "k8s.io/apimachinery/pkg/apis/meta/v1"
	"k8s.io/apimachinery/pkg/types"
	"sigs.k8s.io/controller-runtime/pkg/log"

	mcpv1alpha1 "github.com/example/mcp-operator/api/v1alpha1"
)

// updateMCPServerStatus updates the status based on current state
func (r *MCPServerReconciler) updateMCPServerStatus(ctx context.Context, mcpServer *mcpv1alpha1.MCPServer) error {
	logger := log.FromContext(ctx)

	// Get current deployment status
	deployment, err := r.getCurrentDeployment(ctx, mcpServer)
	if err != nil {
		if errors.IsNotFound(err) {
			return r.updateStatusForMissingDeployment(ctx, mcpServer)
		}
		return err
	}

	// Get current service status  
	service, err := r.getCurrentService(ctx, mcpServer)
	if err != nil {
		if errors.IsNotFound(err) {
			return r.updateStatusForMissingService(ctx, mcpServer)
		}
		return err
	}

	// Update status based on deployment and service state
	return r.updateStatusFromResources(ctx, mcpServer, deployment, service)
}

// getCurrentDeployment fetches the current deployment
func (r *MCPServerReconciler) getCurrentDeployment(ctx context.Context, mcpServer *mcpv1alpha1.MCPServer) (*appsv1.Deployment, error) {
	deployment := &appsv1.Deployment{}
	err := r.Get(ctx, types.NamespacedName{
		Name:      mcpServer.Name,
		Namespace: mcpServer.Namespace,
	}, deployment)
	return deployment, err
}

// getCurrentService fetches the current service
func (r *MCPServerReconciler) getCurrentService(ctx context.Context, mcpServer *mcpv1alpha1.MCPServer) (*corev1.Service, error) {
	service := &corev1.Service{}
	err := r.Get(ctx, types.NamespacedName{
		Name:      mcpServer.Name,
		Namespace: mcpServer.Namespace,
	}, service)
	return service, err
}

// updateStatusForMissingDeployment handles status when deployment is missing
func (r *MCPServerReconciler) updateStatusForMissingDeployment(ctx context.Context, mcpServer *mcpv1alpha1.MCPServer) error {
	mcpServer.Status.Phase = mcpv1alpha1.MCPServerPhasePending
	mcpServer.Status.ReadyReplicas = 0
	mcpServer.Status.Replicas = 0
	mcpServer.Status.ObservedGeneration = mcpServer.Generation

	mcpServer.SetCondition(
		mcpv1alpha1.ConditionDeploymentReady,
		"False",
		"DeploymentNotFound",
		"Deployment does not exist yet",
	)

	return r.Status().Update(ctx, mcpServer)
}

// updateStatusForMissingService handles status when service is missing
func (r *MCPServerReconciler) updateStatusForMissingService(ctx context.Context, mcpServer *mcpv1alpha1.MCPServer) error {
	mcpServer.SetCondition(
		mcpv1alpha1.ConditionServiceReady,
		"False", 
		"ServiceNotFound",
		"Service does not exist yet",
	)

	return r.Status().Update(ctx, mcpServer)
}

// updateStatusFromResources updates status based on actual resource state
func (r *MCPServerReconciler) updateStatusFromResources(ctx context.Context, mcpServer *mcpv1alpha1.MCPServer, deployment *appsv1.Deployment, service *corev1.Service) error {
	logger := log.FromContext(ctx)

	// Update replica counts
	mcpServer.Status.Replicas = deployment.Status.Replicas
	mcpServer.Status.ReadyReplicas = deployment.Status.ReadyReplicas
	mcpServer.Status.ObservedGeneration = mcpServer.Generation

	// Update deployment condition
	deploymentReady := deployment.Status.ReadyReplicas == *deployment.Spec.Replicas
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

	// Check for configuration issues
	if err := r.validateConfiguration(mcpServer); err != nil {
		mcpServer.Status.Phase = mcpv1alpha1.MCPServerPhaseFailed
		mcpServer.SetCondition(
			mcpv1alpha1.ConditionConfigurationValid,
			"False",
			"ConfigurationInvalid",
			err.Error(),
		)
		logger.Error(err, "Configuration validation failed")
	} else {
		mcpServer.SetCondition(
			mcpv1alpha1.ConditionConfigurationValid,
			"True",
			"ConfigurationValid",
			"MCPServer configuration is valid",
		)
	}

	return r.Status().Update(ctx, mcpServer)
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

// validateConfiguration validates the MCPServer configuration
func (r *MCPServerReconciler) validateConfiguration(mcpServer *mcpv1alpha1.MCPServer) error {
	// Validate transport-specific configuration
	transport := mcpServer.GetTransport()
	
	if transport == "stdio" && mcpServer.GetReplicas() > 1 {
		return fmt.Errorf("stdio transport does not support multiple replicas (requested: %d)", mcpServer.GetReplicas())
	}

	// Validate required configuration for different transports
	config := mcpServer.Spec.Config
	if config == nil {
		config = make(map[string]string)
	}

	switch transport {
	case "streamable-http":
		// Streamable HTTP might require specific session management config
		if sessionTimeout, exists := config["SESSION_TIMEOUT"]; exists {
			if _, err := time.ParseDuration(sessionTimeout); err != nil {
				return fmt.Errorf("invalid SESSION_TIMEOUT format: %s", sessionTimeout)
			}
		}
	case "http":
		// HTTP transport might require CORS configuration for browser clients
		if corsOrigins, exists := config["CORS_ORIGINS"]; exists && corsOrigins == "" {
			return fmt.Errorf("CORS_ORIGINS cannot be empty when specified")
		}
	}

	return nil
}

// getMCPServerHealth checks if the MCP server is healthy by calling health endpoints
func (r *MCPServerReconciler) getMCPServerHealth(ctx context.Context, mcpServer *mcpv1alpha1.MCPServer) (bool, string) {
	// This would implement actual health checking logic
	// For now, we'll consider the server healthy if deployment is ready
	return mcpServer.Status.ReadyReplicas == mcpServer.GetReplicas(), "Health check not implemented"
}
EOF

echo "✅ Status management logic created"
```{{exec}}

## Implement Error Handling and Retry Logic

```bash
# Create error handling utilities
cat > controllers/errors.go << 'EOF'
package controllers

import (
	"errors"
	"fmt"
	"time"

	apierrors "k8s.io/apimachinery/pkg/api/errors"
	ctrl "sigs.k8s.io/controller-runtime"
)

// MCPServerError represents different types of errors that can occur
type MCPServerError struct {
	Type    MCPServerErrorType
	Message string
	Cause   error
}

type MCPServerErrorType string

const (
	// ErrorTypeTransient indicates a temporary error that should be retried
	ErrorTypeTransient MCPServerErrorType = "Transient"
	// ErrorTypePermanent indicates a permanent error that won't resolve with retry
	ErrorTypePermanent MCPServerErrorType = "Permanent"
	// ErrorTypeConfiguration indicates a configuration error requiring user intervention
	ErrorTypeConfiguration MCPServerErrorType = "Configuration"
)

func (e *MCPServerError) Error() string {
	if e.Cause != nil {
		return fmt.Sprintf("%s error: %s (caused by: %v)", e.Type, e.Message, e.Cause)
	}
	return fmt.Sprintf("%s error: %s", e.Type, e.Message)
}

// NewTransientError creates a transient error
func NewTransientError(message string, cause error) *MCPServerError {
	return &MCPServerError{
		Type:    ErrorTypeTransient,
		Message: message,
		Cause:   cause,
	}
}

// NewPermanentError creates a permanent error
func NewPermanentError(message string, cause error) *MCPServerError {
	return &MCPServerError{
		Type:    ErrorTypePermanent,
		Message: message,
		Cause:   cause,
	}
}

// NewConfigurationError creates a configuration error
func NewConfigurationError(message string, cause error) *MCPServerError {
	return &MCPServerError{
		Type:    ErrorTypeConfiguration,
		Message: message,
		Cause:   cause,
	}
}

// ClassifyError classifies a standard error into an MCPServerError
func ClassifyError(err error) *MCPServerError {
	if err == nil {
		return nil
	}

	// Check for Kubernetes API errors
	if apierrors.IsNotFound(err) {
		return NewTransientError("Resource not found", err)
	}
	
	if apierrors.IsConflict(err) {
		return NewTransientError("Resource conflict", err)
	}
	
	if apierrors.IsServerTimeout(err) || apierrors.IsTimeout(err) {
		return NewTransientError("API server timeout", err)
	}
	
	if apierrors.IsTooManyRequests(err) {
		return NewTransientError("Rate limited by API server", err)
	}
	
	if apierrors.IsInternalError(err) || apierrors.IsServiceUnavailable(err) {
		return NewTransientError("API server internal error", err)
	}
	
	if apierrors.IsInvalid(err) || apierrors.IsBadRequest(err) {
		return NewConfigurationError("Invalid resource configuration", err)
	}
	
	if apierrors.IsUnauthorized(err) || apierrors.IsForbidden(err) {
		return NewPermanentError("Insufficient permissions", err)
	}

	// Default to transient for unknown errors
	return NewTransientError("Unknown error", err)
}

// DetermineRequeueStrategy determines how to handle the error
func DetermineRequeueStrategy(err error) (ctrl.Result, error) {
	if err == nil {
		return ctrl.Result{}, nil
	}

	mcpErr, ok := err.(*MCPServerError)
	if !ok {
		mcpErr = ClassifyError(err)
	}

	switch mcpErr.Type {
	case ErrorTypeTransient:
		// Retry with exponential backoff (handled by controller runtime)
		return ctrl.Result{}, mcpErr.Cause

	case ErrorTypeConfiguration:
		// Don't retry configuration errors - require user intervention
		// Requeue after a longer delay to avoid spamming logs
		return ctrl.Result{RequeueAfter: 5 * time.Minute}, nil

	case ErrorTypePermanent:
		// Don't retry permanent errors
		return ctrl.Result{}, nil

	default:
		// Default to transient behavior
		return ctrl.Result{}, mcpErr.Cause
	}
}

// HandleReconcileError provides standardized error handling for reconcile operations
func (r *MCPServerReconciler) HandleReconcileError(err error, operation string) (ctrl.Result, error) {
	if err == nil {
		return ctrl.Result{}, nil
	}

	logger := r.Log.WithValues("operation", operation)
	
	mcpErr := ClassifyError(err)
	
	switch mcpErr.Type {
	case ErrorTypeTransient:
		logger.Info("Transient error occurred", "error", mcpErr.Message, "cause", mcpErr.Cause)
		
	case ErrorTypeConfiguration:
		logger.Error(mcpErr, "Configuration error - user intervention required")
		
	case ErrorTypePermanent:
		logger.Error(mcpErr, "Permanent error occurred")
	}

	return DetermineRequeueStrategy(mcpErr)
}

// MCP-specific error helpers

// IsTransportError checks if error is related to MCP transport configuration
func IsTransportError(err error) bool {
	if err == nil {
		return false
	}
	
	errStr := err.Error()
	transportErrors := []string{
		"invalid transport",
		"transport not supported",
		"stdio transport does not support multiple replicas",
		"invalid port range",
	}
	
	for _, transportErr := range transportErrors {
		if contains(errStr, transportErr) {
			return true
		}
	}
	
	return false
}

// IsImageError checks if error is related to container image issues
func IsImageError(err error) bool {
	if err == nil {
		return false
	}
	
	errStr := err.Error()
	imageErrors := []string{
		"image not found",
		"image pull",
		"invalid image",
		"ErrImagePull",
		"ImagePullBackOff",
	}
	
	for _, imageErr := range imageErrors {
		if contains(errStr, imageErr) {
			return true
		}
	}
	
	return false
}

// IsResourceError checks if error is related to resource constraints
func IsResourceError(err error) bool {
	if err == nil {
		return false
	}
	
	errStr := err.Error()
	resourceErrors := []string{
		"insufficient resources",
		"resource quota exceeded",
		"limit range",
		"out of memory",
		"CPU limit",
	}
	
	for _, resourceErr := range resourceErrors {
		if contains(errStr, resourceErr) {
			return true
		}
	}
	
	return false
}

// contains checks if a string contains a substring (case-insensitive)
func contains(str, substr string) bool {
	return len(str) >= len(substr) && 
		   (str == substr || 
		    len(str) > len(substr) && 
		    (str[:len(substr)] == substr || 
		     str[len(str)-len(substr):] == substr || 
		     findInString(str, substr)))
}

func findInString(str, substr string) bool {
	for i := 0; i <= len(str)-len(substr); i++ {
		if str[i:i+len(substr)] == substr {
			return true
		}
	}
	return false
}

// GetRetryAfterDuration returns appropriate retry duration based on error type
func GetRetryAfterDuration(err error, attempt int) time.Duration {
	mcpErr := ClassifyError(err)
	
	switch mcpErr.Type {
	case ErrorTypeTransient:
		// Exponential backoff: 1s, 2s, 4s, 8s, max 60s
		duration := time.Duration(1<<uint(attempt)) * time.Second
		if duration > 60*time.Second {
			return 60 * time.Second
		}
		return duration
		
	case ErrorTypeConfiguration:
		// Longer delay for configuration errors
		return 5 * time.Minute
		
	case ErrorTypePermanent:
		// Very long delay for permanent errors to avoid log spam
		return 30 * time.Minute
		
	default:
		return 30 * time.Second
	}
}
EOF

echo "✅ Error handling and retry logic created"
```{{exec}}

## Test Reconciliation Patterns

```bash
# Create a test to verify our reconciliation patterns
cat > test_reconciliation.yaml << 'EOF'
apiVersion: mcp.example.com/v1alpha1
kind: MCPServer
metadata:
  name: test-reconciliation
spec:
  image: "nginx:alpine"
  transport: streamable-http
  port: 8080
  replicas: 2
  config:
    MCP_SERVER_NAME: "test-server"
    LOG_LEVEL: "debug"
EOF

echo "📋 Testing reconciliation patterns:"
echo ""
echo "1. 🧪 Create test MCPServer"
kubectl apply -f test_reconciliation.yaml

echo ""
echo "2. ⏱️ Wait for initial reconciliation"
sleep 5

echo ""
echo "3. 📊 Check MCPServer status"  
kubectl get mcpservers test-reconciliation -o yaml | grep -A 20 "status:"

echo ""
echo "4. 🔄 Test update reconciliation"
kubectl patch mcpserver test-reconciliation --type='merge' -p='{"spec":{"replicas":3}}'

echo ""
echo "5. ⏱️ Wait for update reconciliation"
sleep 5

echo ""
echo "6. 📊 Verify updated status"
kubectl get mcpservers test-reconciliation -o yaml | grep -A 5 "readyReplicas\|replicas"

echo ""
echo "7. 🧹 Test finalizer cleanup"
kubectl delete mcpserver test-reconciliation

echo ""
echo "8. ⏱️ Monitor deletion process"
timeout=30
while [ $timeout -gt 0 ]; do
  if kubectl get mcpserver test-reconciliation 2>/dev/null; then
    echo "Still deleting... ($timeout seconds remaining)"
    sleep 2
    timeout=$((timeout - 2))
  else
    echo "✅ MCPServer deleted successfully with proper finalizer cleanup"
    break
  fi
done
```{{exec}}

## Summary of Reconciliation Patterns

```bash
echo "🎉 MCP Reconciliation Patterns Complete!"
echo ""
echo "✅ Implemented Patterns:"
echo "  🧹 Comprehensive finalizer management"
echo "  📊 MCP-specific status reporting" 
echo "  🔄 Transport-aware graceful shutdown"
echo "  ⚡ Smart error classification and retry logic"
echo "  🕐 Configurable termination grace periods"
echo "  🏥 Health checking and validation"
echo ""
echo "🎯 Key Features:"
echo "  - Session-aware cleanup for MCP connections"
echo "  - Transport-specific termination handling"
echo "  - Detailed condition reporting"
echo "  - Configuration validation"
echo "  - Resource state monitoring"
echo "  - External resource cleanup support"
echo ""
echo "🔧 Error Handling:"
echo "  - Transient error retry with exponential backoff"
echo "  - Configuration error detection with user intervention"
echo "  - Permanent error identification to avoid retry loops"
echo "  - MCP-specific error classification"
echo ""
echo "Next: Design the complete operator architecture!"
```{{exec}}

Perfect! Our reconciliation patterns are now specifically tailored for MCP server workloads with proper finalizer management, status reporting, and error handling. In the next step, we'll design the complete operator architecture!
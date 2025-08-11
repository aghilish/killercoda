# Step 6: Kubernetes Controllers and Reconciliation Fundamentals

Now we transition from MCP to Kubernetes! Let's dive deep into how Kubernetes controllers work and understand the reconciliation patterns we'll use for our MCP Server operator.

## Understanding Kubernetes Controllers

Controllers are the brain of Kubernetes - they continuously watch the cluster state and take actions to move from current state to desired state.

```bash
# Let's examine existing controllers in action
echo "=== Kubernetes Controllers in Action ==="
kubectl get deployment --all-namespaces
kubectl get replicasets --all-namespaces
kubectl get pods --all-namespaces | head -5
```{{exec}}

## The Reconciliation Loop

Every Kubernetes controller follows the same fundamental pattern:

```bash
cat > /tmp/reconciliation-pattern.yaml << 'EOF'
# Reconciliation Loop Pattern:
# 1. Watch → Get notified of resource changes
# 2. Queue → Add reconciliation request to work queue  
# 3. Reconcile → Compare desired vs actual state
# 4. Act → Take action to close the gap
# 5. Status → Update resource status
# 6. Requeue → Schedule next reconciliation if needed
EOF

echo "📋 Reconciliation Loop Pattern:"
cat /tmp/reconciliation-pattern.yaml
```{{exec}}

## Level-Based vs Edge-Based Reconciliation

```bash
echo "🎯 Level-Based Reconciliation (Kubernetes approach):"
echo "  ✅ Acts on current state, not individual events"
echo "  ✅ Self-healing - automatically corrects drift"
echo "  ✅ Resilient to missed events"
echo "  ✅ Idempotent operations"
echo ""
echo "⚠️  Edge-Based Processing (traditional approach):"
echo "  ❌ Acts on individual events"
echo "  ❌ Can miss events due to failures"
echo "  ❌ Requires complex state tracking"
echo "  ❌ Harder to handle race conditions"
```{{exec}}

## Observing Controller Behavior

Let's create a simple deployment and observe how controllers work:

```bash
# Create a test deployment
kubectl create deployment nginx-test --image=nginx:alpine --replicas=2

echo "⏱️  Waiting for deployment to be ready..."
kubectl rollout status deployment nginx-test

echo "📊 Let's examine what the controllers created:"
echo ""
echo "1. Deployment Controller created ReplicaSet:"
kubectl get replicasets -l app=nginx-test

echo ""
echo "2. ReplicaSet Controller created Pods:"
kubectl get pods -l app=nginx-test

echo ""
echo "3. Let's look at owner references:"
kubectl get pod -l app=nginx-test -o jsonpath='{.items[0].metadata.ownerReferences}' | jq '.'
```{{exec}}

## Controller Patterns for MCP Servers

Now let's think about our MCPServer controller patterns:

```bash
echo "🏗️  MCPServer Controller Patterns:"
echo ""
echo "Resources Managed:"
echo "  📦 MCPServer (Custom Resource) - desired state"
echo "  🚀 Deployment - runs MCP server pods"  
echo "  🌐 Service - exposes MCP server"
echo "  📋 ConfigMap - MCP server configuration"
echo "  🔐 Secret - credentials and certificates"
echo ""
echo "Control Flow:"
echo "  MCPServer CR → Controller → Deployment/Service → Pods → MCP Server"
```{{exec}}

## Finalizers and Cleanup

Understanding finalizers is crucial for proper resource cleanup:

```bash
echo "🧹 Finalizers Pattern:"
echo "  1. Controller adds finalizer on first reconciliation"
echo "  2. Resource deletion sets deletionTimestamp"  
echo "  3. Controller performs cleanup while finalizer exists"
echo "  4. Controller removes finalizer when cleanup complete"
echo "  5. Kubernetes deletes the resource"
echo ""
echo "Why Finalizers?"
echo "  ✅ Guaranteed cleanup of dependent resources"
echo "  ✅ Prevent orphaned resources"
echo "  ✅ Handle complex deletion scenarios"
```{{exec}}

## Error Handling and Retry Strategies

```bash
echo "🔄 Controller Error Handling:"
echo ""
echo "Exponential Backoff:"
echo "  - Failed reconciliation → exponential delay"
echo "  - Per-resource retry timers"
echo "  - Prevents overwhelming API server"
echo ""
echo "Requeue Strategies:"
echo "  - RequeueAfter: scheduled reconciliation"
echo "  - Requeue: immediate requeue with backoff"
echo "  - No requeue: wait for next event"
echo ""
echo "Error Types:"
echo "  - Temporary: network issues, API throttling"
echo "  - Permanent: invalid configuration, missing CRDs"
echo "  - Terminal: user errors, validation failures"
```{{exec}}

## Status Management

```bash
echo "📈 Status Subresource Pattern:"
echo ""
echo "Status reflects observed state:"
echo "  - Conditions: human-readable status information"
echo "  - Phase: current lifecycle stage"  
echo "  - ObservedGeneration: spec version processed"
echo "  - Ready: boolean readiness status"
echo ""
echo "MCPServer Status Example:"
cat << 'EOF'
status:
  conditions:
  - type: Ready
    status: "True"
    reason: MCPServerReady
    message: "MCP server is running and healthy"
  - type: ServiceReady
    status: "True"
    reason: ServiceCreated
  phase: Ready
  observedGeneration: 1
  endpoint: "http://mcp-server-example.default.svc.cluster.local:8080"
EOF
```{{exec}}

## RBAC for Controllers

```bash
echo "🔐 Controller RBAC Requirements:"
echo ""
echo "MCPServer Controller needs permissions for:"
echo "  - MCPServer resources: get, list, watch, patch"
echo "  - MCPServer/status: get, update, patch"  
echo "  - MCPServer/finalizers: update"
echo "  - Deployments: get, list, watch, create, update, patch, delete"
echo "  - Services: get, list, watch, create, update, patch, delete"
echo "  - ConfigMaps: get, list, watch, create, update, patch, delete"
echo "  - Secrets: get, list, watch, create, update, patch, delete"
echo "  - Events: create, patch"
```{{exec}}

## Reconciliation Context

Let's understand the reconciliation context:

```bash
echo "🎯 Reconciliation Context:"
echo ""
echo "Input: ctrl.Request"
echo "  - NamespacedName (namespace/name of resource)"
echo "  - NO resource object (must fetch current state)"
echo ""
echo "Why NamespacedName only?"
echo "  ✅ Handles resource deletion gracefully"
echo "  ✅ Always gets latest state from API server"
echo "  ✅ Avoids stale cached data"
echo "  ✅ Supports queue deduplication"
echo ""
echo "Controller Responsibilities:"
echo "  1. Fetch current resource state"
echo "  2. Handle resource not found (deleted)"
echo "  3. Check for deletion (finalizer logic)"
echo "  4. Reconcile to desired state"
echo "  5. Update status"
echo "  6. Return result (requeue if needed)"
```{{exec}}

## Testing Controller Behavior

```bash
echo "🧪 Testing Reconciliation:"
echo ""
echo "Observing self-healing behavior..."

# Scale down one pod manually
POD_NAME=$(kubectl get pods -l app=nginx-test -o jsonpath='{.items[0].metadata.name}')
echo "Deleting pod: $POD_NAME"
kubectl delete pod $POD_NAME

echo "⏱️  Waiting to observe self-healing..."
sleep 3

echo "📊 Pods after deletion (ReplicaSet controller recreated):"
kubectl get pods -l app=nginx-test

# Cleanup
kubectl delete deployment nginx-test
```{{exec}}

## Summary: Controller Fundamentals

```bash
echo "✅ Controller Fundamentals Summary:"
echo ""
echo "🔄 Key Concepts:"
echo "  - Level-based reconciliation (not event-driven)"
echo "  - Idempotent operations"
echo "  - Exponential backoff for errors"
echo "  - Finalizers for cleanup"
echo "  - Status subresource for observed state"
echo ""
echo "🎯 For MCPServer Operator:"
echo "  - Watch MCPServer resources"
echo "  - Manage Deployment/Service/ConfigMap"
echo "  - Handle MCP server lifecycle"
echo "  - Report status and health"
echo "  - Clean up on deletion"
```{{exec}}

Perfect! Now you understand Kubernetes controller fundamentals. Next, we'll define our MCPServer custom resource!
# Step 10: Production Deployment and Service Management

Now let's deploy our complete MCPServer operator and test it with real MCP server workloads. We'll build Docker images, deploy the operator, and manage MCPServer resources in production.

## Build and Deploy the Operator

Let's build our operator and deploy it to the cluster:

```bash
# Switch to our operator workspace
cd /workspace/mcp-operator

# Build Docker image for the operator
echo "=== Building Operator Docker Image ==="
make docker-build IMG=mcp-operator:latest

# Load image into Kind cluster (for local testing)
if command -v kind >/dev/null 2>&1; then
    kind load docker-image mcp-operator:latest
    echo "✅ Operator image loaded into Kind cluster"
fi

echo "✅ MCPServer operator Docker image built"
```{{exec}}

## Build MCP Server Docker Image

First, let's build a Docker image for our MCP server from the lab:

```bash
# Switch to MCP lab directory to build our server image
cd /workspace/mcp-lab

# Build Docker image from our tested MCP server
echo "=== Building MCP Server Docker Image ==="
docker build -t mcp-k8s-server:latest .

# Load image into Kind cluster (for local testing)
if command -v kind >/dev/null 2>&1; then
    kind load docker-image mcp-k8s-server:latest
    echo "✅ MCP server image loaded into Kind cluster"
fi

echo "✅ MCP Server Docker image built and ready"
```{{exec}}

## Deploy the Operator

Now let's deploy our operator to the cluster:

```bash
# Switch back to operator directory
cd /workspace/mcp-operator

# Deploy the operator to the cluster
echo "=== Deploying MCPServer Operator ==="
make deploy IMG=mcp-operator:latest

echo "✅ MCPServer operator deployed"
```{{exec}}

## Verify Operator Deployment

Let's verify the operator is running correctly:

```bash
# Check operator deployment
echo "=== Checking Operator Status ==="
kubectl get deployment -n mcp-operator-system

# Check operator pods
kubectl get pods -n mcp-operator-system

# Check operator logs
echo ""
echo "=== Recent Operator Logs ==="
kubectl logs -n mcp-operator-system -l control-plane=controller-manager --tail=20

echo "✅ Operator verification completed"
```{{exec}}

## Create Production MCPServer Instances

Now let's create our MCPServer instances using the operator:

```bash
# Create updated sample manifests with our built image
cat > basic-mcpserver.yaml << 'EOF'
apiVersion: mcp.example.com/v1alpha1
kind: MCPServer
metadata:
  name: basic-mcpserver
  namespace: default
  labels:
    environment: development
spec:
  image: "mcp-k8s-server:latest"
  transport: streamable-http
  port: 3001
  replicas: 1
  config:
    MCP_SERVER_NAME: "basic-kubernetes-server"
    LOG_LEVEL: "info"
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

# Create advanced production MCPServer
cat > advanced-mcpserver.yaml << 'EOF'
apiVersion: mcp.example.com/v1alpha1
kind: MCPServer
metadata:
  name: advanced-mcpserver
  namespace: default
  labels:
    environment: production
    team: ai-platform
spec:
  image: "mcp-k8s-server:latest"
  transport: streamable-http
  port: 3001
  replicas: 2
  config:
    MCP_SERVER_NAME: "production-k8s-server"
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

echo "✅ MCPServer manifests created"
```{{exec}}

## Deploy and Test MCPServer Instances

Let's deploy our MCPServer instances and test them:

```bash
# Deploy basic MCPServer
echo "=== Deploying Basic MCPServer ==="
kubectl apply -f basic-mcpserver.yaml

# Wait for it to become ready
echo "Waiting for basic MCPServer to be ready..."
kubectl wait --for=condition=Ready mcpserver/basic-mcpserver --timeout=120s

# Check status
kubectl get mcpservers basic-mcpserver
kubectl describe mcpserver basic-mcpserver

echo "✅ Basic MCPServer deployed and ready"
```{{exec}}

## Test MCP Server Connectivity

Let's test the deployed MCP server:

```bash
# Get the service endpoint
echo "=== Testing MCP Server Connectivity ==="
SERVICE_IP=$(kubectl get service basic-mcpserver -o jsonpath='{.spec.clusterIP}')
SERVICE_PORT=$(kubectl get service basic-mcpserver -o jsonpath='{.spec.ports[0].port}')

echo "MCP Server Service: $SERVICE_IP:$SERVICE_PORT"

# Test health endpoint
echo ""
echo "Testing health endpoint..."
if kubectl run test-client --image=alpine/curl --rm -it --restart=Never -- \
   curl -s "http://$SERVICE_IP:$SERVICE_PORT/health"; then
    echo "✅ Health endpoint responding"
else
    echo "❌ Health endpoint not accessible"
fi

# Test MCP protocol endpoint
echo ""
echo "Testing MCP protocol endpoint..."
kubectl run test-mcp-client --image=alpine/curl --rm -it --restart=Never -- \
   curl -s -X POST "http://$SERVICE_IP:$SERVICE_PORT/mcp" \
   -H "Content-Type: application/json" \
   -d '{"jsonrpc": "2.0", "id": 1, "method": "initialize", "params": {}}'

echo "✅ MCP protocol endpoint tested"
```{{exec}}

## Deploy Advanced MCPServer

Now let's deploy the advanced production MCPServer:

```bash
# Deploy advanced MCPServer
echo "=== Deploying Advanced MCPServer ==="
kubectl apply -f advanced-mcpserver.yaml

# Wait for it to become ready
echo "Waiting for advanced MCPServer to be ready..."
kubectl wait --for=condition=Ready mcpserver/advanced-mcpserver --timeout=120s

# Check status of all MCPServers
echo ""
echo "=== All MCPServers Status ==="
kubectl get mcpservers
kubectl get pods -l app.kubernetes.io/name=mcp-server

echo "✅ Advanced MCPServer deployed"
```{{exec}}

## Test Scaling and Management

Let's test the scaling capabilities:

```bash
# Test scaling the advanced MCPServer
echo "=== Testing MCPServer Scaling ==="
kubectl patch mcpserver advanced-mcpserver --type='merge' -p='{"spec":{"replicas":3}}'

# Wait for scale operation
echo "Waiting for scale operation..."
sleep 10

# Check scaling results
kubectl get mcpservers advanced-mcpserver
kubectl get pods -l app.kubernetes.io/instance=advanced-mcpserver

# Test configuration update
echo ""
echo "=== Testing Configuration Update ==="
kubectl patch mcpserver advanced-mcpserver --type='merge' -p='{"spec":{"config":{"LOG_LEVEL":"debug","NEW_SETTING":"enabled"}}}'

# Wait for update
sleep 10

# Check updated configuration
kubectl describe mcpserver advanced-mcpserver | grep -A 10 "Config:"

echo "✅ Scaling and configuration updates tested"
```{{exec}}

## Monitor Resource Status

Let's examine the comprehensive status reporting:

```bash
# Check detailed status of all resources
echo "=== MCPServer Resource Status ==="

# MCPServer status
kubectl get mcpservers -o wide
echo ""

# Deployments created by the operator
kubectl get deployments -l app.kubernetes.io/managed-by=mcp-operator
echo ""

# Services created by the operator  
kubectl get services -l app.kubernetes.io/managed-by=mcp-operator
echo ""

# ConfigMaps created by the operator
kubectl get configmaps -l app.kubernetes.io/managed-by=mcp-operator
echo ""

# Pods running our MCP servers
kubectl get pods -l app.kubernetes.io/name=mcp-server -o wide
echo ""

# Check conditions and status
echo "=== MCPServer Conditions ==="
kubectl get mcpserver basic-mcpserver -o jsonpath='{.status.conditions}' | jq '.'
kubectl get mcpserver advanced-mcpserver -o jsonpath='{.status.conditions}' | jq '.'

echo "✅ Resource status monitoring completed"
```{{exec}}

## Test Cleanup and Finalizers

Let's test the cleanup process:

```bash
# Test graceful deletion
echo "=== Testing MCPServer Deletion ==="

# Delete basic MCPServer and monitor cleanup
kubectl delete mcpserver basic-mcpserver

# Monitor deletion process
echo "Monitoring deletion process..."
timeout=30
while [ $timeout -gt 0 ] && kubectl get mcpserver basic-mcpserver 2>/dev/null; do
    echo "Still deleting... ($timeout seconds remaining)"
    kubectl get mcpserver basic-mcpserver -o jsonpath='{.metadata.deletionTimestamp}' 2>/dev/null
    sleep 2
    timeout=$((timeout - 2))
done

# Verify all resources are cleaned up
echo ""
echo "=== Verifying Cleanup ==="
if kubectl get mcpserver basic-mcpserver 2>/dev/null; then
    echo "❌ MCPServer still exists"
else
    echo "✅ MCPServer deleted successfully"
fi

# Check if related resources are cleaned up
kubectl get deployments -l app.kubernetes.io/instance=basic-mcpserver
kubectl get services -l app.kubernetes.io/instance=basic-mcpserver
kubectl get pods -l app.kubernetes.io/instance=basic-mcpserver

echo "✅ Cleanup verification completed"
```{{exec}}

## Production Deployment Summary

Let's summarize what we've accomplished:

```bash
echo "==========================================="
echo "🚀 Production Deployment Summary"
echo "==========================================="
echo ""
echo "✅ Successfully Deployed:"
echo "  🏗️  MCPServer Operator with full reconciliation"
echo "  🐳 Docker images for operator and MCP server"
echo "  📦 Custom Resource Definitions (CRDs)"
echo "  🎯 RBAC configuration and permissions"
echo "  🔄 Controller manager with leader election"
echo ""
echo "✅ Tested Features:"
echo "  🚀 MCPServer resource creation and management"
echo "  📊 Comprehensive status reporting with conditions"
echo "  📈 Dynamic scaling (1 → 2 → 3 replicas)"
echo "  ⚙️  Configuration updates and rollouts"
echo "  🧹 Graceful deletion with finalizer cleanup"
echo "  🌐 Service creation and networking"
echo "  🔍 Health checks and readiness probes"
echo ""
echo "✅ Production-Ready Components:"
echo "  🎛️  Controller with proper error handling"
echo "  📋 ConfigMap-based configuration management"
echo "  🔐 Security context and RBAC policies"
echo "  📊 Detailed status and condition reporting"
echo "  🏷️  Proper labeling and owner references"
echo "  ⚡ Efficient resource reconciliation"
echo ""
echo "🎉 MCPServer Operator is production-ready!"
echo "==========================================="
```{{exec}}

Perfect! We now have a fully functional, production-ready MCPServer operator that can deploy, scale, and manage MCP servers in Kubernetes. In the final step, we'll cover production considerations and best practices!
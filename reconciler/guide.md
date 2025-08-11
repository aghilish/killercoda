# 🚀 MCP Server Operator for Kubernetes & Ollama LLM

A full guide to build a Kubernetes operator that manages MCP servers, deploys them in a Kind cluster, and connects them to a local Ollama-hosted LLM acting as an MCP client.

## 🧠 1. Understanding Reconciliation

Kubernetes controllers use a **level-based reconciliation model**, meaning they act on actual cluster state rather than mere events.

- Fetch the latest resource via the API server or cache
- Exit on deletion (e.g., `IsNotFound`)
- Perform **idempotent** operations
- Use **finalizers** for safe cleanup
- Errors trigger **exponential backoff retries**, while `RequeueAfter` enables scheduled re-run

These patterns ensure correctness, scalability, and robustness.

## 💡 2. Defining Your MCPServer CRD

Create `config/crd/bases/mcp.example.com_mcpservers.yaml`:

```yaml
apiVersion: mcp.example.com/v1alpha1
kind: MCPServer
metadata:
  name: example
spec:
  image: ollama-mcp:latest
  port: 8000
  schedule: "*/5 * * * *" # health check every 5 minutes
```

Fields:

- `image`: container image running your MCP server
- `port`: service port
- `schedule`: optional cron-style requeue interval

## 🔧 3. Generating the Operator Skeleton

```bash
# Initialize project
kubebuilder init --domain example.com --repo github.com/you/mcp-operator

# Create API + Controller
kubebuilder create api --group mcp.example.com --version v1alpha1   --kind MCPServer --controller --resource
```

Add RBAC markers in `api/v1alpha1/mcpserver_types.go`:

```go
//+kubebuilder:rbac:groups=mcp.example.com,resources=mcpservers,verbs=get;list;watch;patch
//+kubebuilder:rbac:groups=mcp.example.com,resources=mcpservers/status,verbs=get;update;patch
//+kubebuilder:rbac:groups=mcp.example.com,resources=mcpservers/finalizers,verbs=update
```

Run:

```bash
make generate
make manifests
```

## 🔧 4. Controller Setup

In `controllers/mcpserver_controller.go`, configure:

```go
func (r *MCPServerReconciler) SetupWithManager(mgr ctrl.Manager) error {
  return ctrl.NewControllerManagedBy(mgr).
    For(&mcpv1.MCPServer{}).
    WithEventFilter(predicate.GenerationChangedPredicate{}).
    WithOptions(controller.Options{
      MaxConcurrentReconciles: 2,
      RateLimiter:            workqueue.DefaultControllerRateLimiter(),
    }).
    Complete(r)
}
```

## ⚙️ 5. Reconcile Loop Structure

```go
func (r *MCPServerReconciler) Reconcile(ctx context.Context, req ctrl.Request) (ctrl.Result, error) {
  log := ctrl.LoggerFrom(ctx)
  m := &mcpv1.MCPServer{}
  if err := r.Get(ctx, req.NamespacedName, m); err != nil {
    if apierrors.IsNotFound(err) {
      return ctrl.Result{}, nil
    }
    return ctrl.Result{}, err
  }

  // Finalizer logic
  if m.DeletionTimestamp == nil {
    if !controllerutil.ContainsFinalizer(m, mcpv1.ServerFinalizer) {
      controllerutil.AddFinalizer(m, mcpv1.ServerFinalizer)
      if err := r.Update(ctx, m); err != nil { return ctrl.Result{}, err }
      return ctrl.Result{}, nil
    }
  } else {
    if controllerutil.ContainsFinalizer(m, mcpv1.ServerFinalizer) {
      if err := r.cleanup(ctx, m); err != nil { return ctrl.Result{}, err }
      controllerutil.RemoveFinalizer(m, mcpv1.ServerFinalizer)
      if err := r.Update(ctx, m); err != nil { return ctrl.Result{}, err }
    }
    return ctrl.Result{}, nil
  }

  // Reconcile Deployment + Service
  if err := r.reconcileDeployment(ctx, m); err != nil { return ctrl.Result{}, err }
  if err := r.reconcileService(ctx, m); err != nil { return ctrl.Result{}, err }
  if err := r.updateStatus(ctx, m); err != nil { return ctrl.Result{}, err }

  // Scheduled requeue
  if m.Spec.Schedule != "" {
    next := computeNextRun(m.Spec.Schedule)
    return ctrl.Result{RequeueAfter: time.Until(next)}, nil
  }

  return ctrl.Result{}, nil
}
```

## 🎯 6. Key Functions

- `reconcileDeployment(ctx, *MCPServer)` – manages pod/deployment creation
- `reconcileService(ctx, *MCPServer)` – exposes service
- `updateStatus(ctx, *MCPServer)` – writes `.status.url = http://…`
- `cleanup(ctx, *MCPServer)` – deletes k8s resources

## ⚙️ 7. Deploy on Kind

```bash
kind create cluster --name mcp
eval $(kind get kubeconfig --name mcp)

# Build operator
make docker-build docker-push IMG=localhost:5000/mcp-operator:latest

# Load into Kind
kind load docker-image localhost:5000/mcp-operator:latest --name mcp

# Deploy operator
kubectl apply -k config/default/

# Deploy an MCPServer CR
cat <<EOF | kubectl apply -f -
apiVersion: mcp.example.com/v1alpha1
kind: MCPServer
metadata:
  name: example-mcp
spec:
  image: ollama-mcp:latest
  port: 8000
  schedule: "*/5 * * * *"
EOF
```

Verify resources:

```bash
kubectl get deployment,svc,mcpserver
kubectl get mcpserver example-mcp -o yaml
```

## 🤖 8. Connect Ollama LLM Client

1. Ensure Ollama is installed and running:

   ```bash
   ollama run qwen2.5
   ```

2. Configure `~/.ollama/config.json`:

   ```json
   {
     "mcpServers": {
       "k8s": {
         "command": "mcphost",
         "args": ["--url", "http://example-mcp.mcp.svc.cluster.local:8000"]
       }
     }
   }
   ```

3. Run:

   ```bash
   mcphost --mcp-urls http://example-mcp.mcp.svc.cluster.local:8000
   ```

In Ollama chat, your MCP tools should now be available under the `k8s` server.

## 🔒 9. Security & Next Steps

- Add MCP **tool schemas** via ConfigMaps for validation
- Implement **RBAC filters** to limit calls
- Extend operator: watch more CRDs, attach Predicates, and scale concurrency

---

Enjoy building your MCP-powered agents with Kubernetes & Ollama 🚀

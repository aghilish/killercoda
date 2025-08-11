# Step 4: Building Your First MCP Server

Now let's build a complete MCP server with Kubernetes integration! We'll create a server that provides tools and resources for managing Kubernetes workloads.

## Create the MCP Server Structure

Let's start by creating our first Kubernetes-aware MCP server:

```bash

# Create the main server file
cat > src/servers/k8s-mcp-server.ts << 'EOF'
import { McpServer } from "@modelcontextprotocol/sdk/server/mcp.js";
import { StdioServerTransport } from "@modelcontextprotocol/sdk/server/stdio.js";
import * as k8s from '@kubernetes/client-node';
import { z } from 'zod';

// Initialize Kubernetes client
const kc = new k8s.KubeConfig();
kc.loadFromDefault();
const k8sApi = kc.makeApiClient(k8s.CoreV1Api);
const appsApi = kc.makeApiClient(k8s.AppsV1Api);

// Create MCP server
const server = new McpServer({
  name: "kubernetes-mcp-server",
  version: "1.0.0"
});

export { server, k8sApi, appsApi };
EOF

echo "Created MCP server structure"
```{{exec}}

## Add Kubernetes Resources

Let's add resources that provide cluster information:

```bash
cat >> src/servers/k8s-mcp-server.ts << 'EOF'

// Resource: Cluster nodes information
server.registerResource(
  "cluster-nodes",
  "k8s://cluster/nodes",
  {
    title: "Kubernetes Cluster Nodes",
    description: "Information about all nodes in the cluster",
    mimeType: "application/json"
  },
  async (uri) => {
    try {
      const response = await k8sApi.listNode();
      const nodes = response.body.items.map(node => ({
        name: node.metadata?.name,
        status: node.status?.conditions?.find(c => c.type === 'Ready')?.status,
        version: node.status?.nodeInfo?.kubeletVersion,
        capacity: {
          cpu: node.status?.capacity?.cpu,
          memory: node.status?.capacity?.memory,
          pods: node.status?.capacity?.pods
        }
      }));

      return {
        contents: [{
          uri: uri.href,
          text: JSON.stringify({ nodes, count: nodes.length }, null, 2)
        }]
      };
    } catch (error) {
      return {
        contents: [{
          uri: uri.href,
          text: `Error fetching nodes: ${error.message}`
        }]
      };
    }
  }
);

// Resource: Namespace pods with dynamic namespace parameter
server.registerResource(
  "namespace-pods",
  "k8s://namespace/{namespace}/pods",
  {
    title: "Kubernetes Namespace Pods",
    description: "List all pods in a specific namespace"
  },
  async (uri, context) => {
    const namespace = context.namespace || 'default';
    
    try {
      const response = await k8sApi.listNamespacedPod(namespace);
      const pods = response.body.items.map(pod => ({
        name: pod.metadata?.name,
        namespace: pod.metadata?.namespace,
        phase: pod.status?.phase,
        ready: pod.status?.containerStatuses?.every(c => c.ready) || false,
        restarts: pod.status?.containerStatuses?.reduce((sum, c) => sum + c.restartCount, 0) || 0,
        age: pod.metadata?.creationTimestamp
      }));

      return {
        contents: [{
          uri: uri.href,
          text: JSON.stringify({ namespace, pods, count: pods.length }, null, 2)
        }]
      };
    } catch (error) {
      return {
        contents: [{
          uri: uri.href,
          text: `Error fetching pods in ${namespace}: ${error.message}`
        }]
      };
    }
  }
);
EOF

echo "Added Kubernetes resources"
```{{exec}}

## Add Kubernetes Tools

Now let's add tools that can perform actions:

```bash
cat >> src/servers/k8s-mcp-server.ts << 'EOF'

// Tool: Create a simple pod
server.registerTool(
  "create-pod",
  {
    title: "Create Kubernetes Pod",
    description: "Create a simple pod with specified image and name",
    inputSchema: {
      name: z.string().describe("Pod name"),
      image: z.string().describe("Container image"),
      namespace: z.string().default("default").describe("Target namespace")
    }
  },
  async ({ name, image, namespace }) => {
    try {
      const podManifest = {
        metadata: { 
          name,
          labels: { 'created-by': 'mcp-server' }
        },
        spec: {
          containers: [{
            name: name,
            image: image,
            resources: {
              requests: { cpu: '100m', memory: '128Mi' },
              limits: { cpu: '500m', memory: '512Mi' }
            }
          }]
        }
      };

      const response = await k8sApi.createNamespacedPod(namespace, podManifest);
      
      return {
        content: [{
          type: "text",
          text: `✅ Successfully created pod "${name}" in namespace "${namespace}"\n` +
                `Image: ${image}\n` +
                `UID: ${response.body.metadata?.uid}`
        }]
      };
    } catch (error) {
      return {
        content: [{
          type: "text", 
          text: `❌ Failed to create pod: ${error.message}`
        }],
        isError: true
      };
    }
  }
);

// Tool: Get pod logs
server.registerTool(
  "get-pod-logs",
  {
    title: "Get Pod Logs", 
    description: "Retrieve logs from a specific pod",
    inputSchema: {
      name: z.string().describe("Pod name"),
      namespace: z.string().default("default").describe("Pod namespace"),
      lines: z.number().default(100).describe("Number of log lines to retrieve")
    }
  },
  async ({ name, namespace, lines }) => {
    try {
      const response = await k8sApi.readNamespacedPodLog(
        name, 
        namespace, 
        undefined, // container name
        false, // follow
        undefined, // limitBytes
        undefined, // pretty
        undefined, // previous
        undefined, // sinceSeconds
        lines // tailLines
      );

      return {
        content: [{
          type: "text",
          text: `📋 Logs for pod "${name}" in namespace "${namespace}":\n\n${response.body}`
        }]
      };
    } catch (error) {
      return {
        content: [{
          type: "text",
          text: `❌ Failed to get logs: ${error.message}`
        }],
        isError: true
      };
    }
  }
);

// Tool: Delete pod
server.registerTool(
  "delete-pod",
  {
    title: "Delete Kubernetes Pod",
    description: "Delete a specific pod", 
    inputSchema: {
      name: z.string().describe("Pod name"),
      namespace: z.string().default("default").describe("Pod namespace")
    }
  },
  async ({ name, namespace }) => {
    try {
      await k8sApi.deleteNamespacedPod(name, namespace);
      
      return {
        content: [{
          type: "text",
          text: `🗑️ Successfully deleted pod "${name}" from namespace "${namespace}"`
        }]
      };
    } catch (error) {
      return {
        content: [{
          type: "text",
          text: `❌ Failed to delete pod: ${error.message}`
        }],
        isError: true
      };
    }
  }
);
EOF

echo "Added Kubernetes tools"
```{{exec}}

## Add MCP Prompts

Let's add some helpful prompts for Kubernetes troubleshooting:

```bash
cat >> src/servers/k8s-mcp-server.ts << 'EOF'

// Prompt: Kubernetes troubleshooting
server.registerPrompt(
  "troubleshoot-pod",
  {
    title: "Troubleshoot Pod Issues",
    description: "Systematic approach to diagnosing pod problems",
    argsSchema: {
      podName: z.string().describe("Name of the pod to troubleshoot"),
      namespace: z.string().default("default").describe("Namespace of the pod")
    }
  },
  ({ podName, namespace }) => ({
    messages: [{
      role: "user",
      content: {
        type: "text", 
        text: `Please help me troubleshoot the Kubernetes pod "${podName}" in namespace "${namespace}". 

Follow this systematic approach:
1. Check pod status and phase
2. Examine recent events
3. Review container logs  
4. Verify resource requests/limits
5. Check network connectivity
6. Validate persistent volume claims
7. Review security contexts and RBAC

Provide step-by-step diagnosis with specific kubectl commands and potential solutions for each issue you identify.`
      }
    }]
  })
);

// Prompt: Resource optimization
server.registerPrompt(
  "optimize-resources",
  {
    title: "Kubernetes Resource Optimization",
    description: "Analyze and optimize resource usage",
    argsSchema: {
      namespace: z.string().default("default").describe("Namespace to analyze")
    }
  },
  ({ namespace }) => ({
    messages: [{
      role: "user",
      content: {
        type: "text",
        text: `Please analyze the resource usage in Kubernetes namespace "${namespace}" and provide optimization recommendations.

Please examine:
1. CPU and memory requests vs limits vs actual usage
2. Pod resource efficiency and right-sizing opportunities
3. Horizontal Pod Autoscaler configuration
4. Resource quotas and limits
5. Node resource allocation and capacity planning

Provide specific recommendations with YAML examples for improvements.`
      }
    }]
  })
);
EOF

echo "Added MCP prompts"
```{{exec}}

## Complete the Server Setup

Let's add the transport connection to make the server runnable:

```bash
cat >> src/servers/k8s-mcp-server.ts << 'EOF'

// Start the server
async function main() {
  try {
    const transport = new StdioServerTransport();
    await server.connect(transport);
    console.error("Kubernetes MCP Server started successfully");
  } catch (error) {
    console.error("Failed to start MCP server:", error);
    process.exit(1);
  }
}

// Run if this file is executed directly
if (import.meta.url === `file://${process.argv[1]}`) {
  main().catch(console.error);
}
EOF

echo "Completed MCP server setup"
```{{exec}}

## Test the MCP Server

Let's build and test our server:

```bash
# Compile TypeScript
npm run build

# Test the server functionality (basic validation)
echo "Testing MCP server compilation and basic structure..."
node -e "
import('./dist/servers/k8s-mcp-server.js')
  .then(() => console.log('✅ MCP server loaded successfully'))
  .catch(e => console.error('❌ Error loading server:', e.message))
"
```{{exec}}

## Verify Kubernetes Integration

Let's test our Kubernetes integration:

```bash
# Quick test of Kubernetes connectivity
echo "Testing Kubernetes API access..."
kubectl get nodes --no-headers | wc -l | xargs echo "Cluster has {} nodes"
kubectl get pods --all-namespaces --no-headers | wc -l | xargs echo "Total pods across all namespaces: {}"

echo "✅ MCP Server with Kubernetes integration is ready!"
echo "📋 Your server provides:"
echo "  - Resources: cluster-nodes, namespace-pods"  
echo "  - Tools: create-pod, get-pod-logs, delete-pod"
echo "  - Prompts: troubleshoot-pod, optimize-resources"
```{{exec}}

Great! You've built your first MCP server with comprehensive Kubernetes integration. In the next step, we'll connect it to AI applications!

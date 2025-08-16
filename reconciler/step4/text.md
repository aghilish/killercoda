# Step 4: Building Your First MCP Server

Now let's build a complete MCP server with Kubernetes integration! We'll create reusable handlers and both stdio and HTTP server implementations.

## Create Shared MCP Handlers

First, let's create reusable handlers that both our stdio and HTTP servers can use:

```bash
# Create shared handlers for MCP protocol operations
cat > src/handlers/k8s-handlers.ts << 'EOF'
import { Server } from "@modelcontextprotocol/sdk/server/index.js";
import * as k8s from '@kubernetes/client-node';
import {
  ListResourcesRequestSchema,
  ReadResourceRequestSchema,
  ListToolsRequestSchema,
  CallToolRequestSchema,
  ListPromptsRequestSchema,
  GetPromptRequestSchema
} from "@modelcontextprotocol/sdk/types.js";

// Initialize Kubernetes client
const kc = new k8s.KubeConfig();
kc.loadFromDefault();
const k8sApi = kc.makeApiClient(k8s.CoreV1Api);
const appsApi = kc.makeApiClient(k8s.AppsV1Api);

// Resource handlers
export function setupResourceHandlers(server: Server) {
  server.setRequestHandler(ListResourcesRequestSchema, async () => {
    return {
      resources: [
        {
          uri: "k8s://cluster/nodes",
          name: "Kubernetes Cluster Nodes",
          description: "Information about all nodes in the cluster",
          mimeType: "application/json"
        },
        {
          uri: "k8s://namespace/default/pods", 
          name: "Default Namespace Pods",
          description: "List all pods in the default namespace",
          mimeType: "application/json"
        }
      ]
    };
  });

  server.setRequestHandler(ReadResourceRequestSchema, async (request) => {
    const { uri } = request.params;
    
    if (uri === "k8s://cluster/nodes") {
      try {
        const response = await k8sApi.listNode();
        const nodes = (response as any).items.map((node: any) => ({
          name: node.metadata?.name,
          status: node.status?.conditions?.find((c: any) => c.type === 'Ready')?.status,
          version: node.status?.nodeInfo?.kubeletVersion,
          capacity: {
            cpu: node.status?.capacity?.cpu,
            memory: node.status?.capacity?.memory,
            pods: node.status?.capacity?.pods
          }
        }));

        return {
          contents: [{
            uri: uri,
            text: JSON.stringify({ nodes, count: nodes.length }, null, 2),
            mimeType: "application/json"
          }]
        };
      } catch (error: any) {
        return {
          contents: [{
            uri: uri,
            text: `Error fetching nodes: ${error.message}`,
            mimeType: "text/plain"
          }]
        };
      }
    }
    
    if (uri.startsWith("k8s://namespace/") && uri.endsWith("/pods")) {
      const namespace = uri.split("/")[3] || "default";
      
      try {
        const response = await k8sApi.listNamespacedPod({ namespace });
        const pods = (response as any).items.map((pod: any) => ({
          name: pod.metadata?.name,
          namespace: pod.metadata?.namespace,
          phase: pod.status?.phase,
          ready: pod.status?.containerStatuses?.every((c: any) => c.ready) || false,
          restarts: pod.status?.containerStatuses?.reduce((sum: any, c: any) => sum + c.restartCount, 0) || 0,
          age: pod.metadata?.creationTimestamp
        }));

        return {
          contents: [{
            uri: uri,
            text: JSON.stringify({ namespace, pods, count: pods.length }, null, 2),
            mimeType: "application/json"
          }]
        };
      } catch (error: any) {
        return {
          contents: [{
            uri: uri,
            text: `Error fetching pods in ${namespace}: ${error.message}`,
            mimeType: "text/plain"
          }]
        };
      }
    }
    
    throw new Error(`Unknown resource: ${uri}`);
  });
}
EOF

echo "✅ Created shared resource handlers"
```{{exec}}

## Add Tool Handlers

Now let's add the tool handlers for performing Kubernetes operations:

```bash
# Continue building the shared handlers file
cat >> src/handlers/k8s-handlers.ts << 'EOF'

// Tool handlers
export function setupToolHandlers(server: Server) {
  server.setRequestHandler(ListToolsRequestSchema, async () => {
    return {
      tools: [
        {
          name: "create-pod",
          description: "Create a simple pod with specified image and name",
          inputSchema: {
            type: "object",
            properties: {
              name: { type: "string", description: "Pod name" },
              image: { type: "string", description: "Container image" },
              namespace: { type: "string", description: "Target namespace", default: "default" }
            },
            required: ["name", "image"]
          }
        },
        {
          name: "get-pod-logs",
          description: "Retrieve logs from a specific pod",
          inputSchema: {
            type: "object",
            properties: {
              name: { type: "string", description: "Pod name" },
              namespace: { type: "string", description: "Pod namespace", default: "default" }
            },
            required: ["name"]
          }
        },
        {
          name: "delete-pod",
          description: "Delete a specific pod",
          inputSchema: {
            type: "object",
            properties: {
              name: { type: "string", description: "Pod name" },
              namespace: { type: "string", description: "Pod namespace", default: "default" }
            },
            required: ["name"]
          }
        }
      ]
    };
  });

  server.setRequestHandler(CallToolRequestSchema, async (request) => {
    const { name, arguments: args } = request.params;
    
    if (name === "create-pod") {
      const { name: podName, image, namespace = "default" } = args as any;
      
      try {
        const podManifest = {
          metadata: { 
            name: podName,
            labels: { 'created-by': 'mcp-server' }
          },
          spec: {
            containers: [{
              name: podName,
              image: image,
              resources: {
                requests: { cpu: '100m', memory: '128Mi' },
                limits: { cpu: '500m', memory: '512Mi' }
              }
            }]
          }
        };

        const response = await k8sApi.createNamespacedPod({ namespace, body: podManifest as any });
        
        return {
          content: [{
            type: "text",
            text: `✅ Successfully created pod "${podName}" in namespace "${namespace}"\n` +
                  `Image: ${image}\n` +
                  `UID: ${(response as any).metadata?.uid}`
          }]
        };
      } catch (error: any) {
        return {
          content: [{
            type: "text",
            text: `❌ Failed to create pod: ${error.message}`
          }],
          isError: true
        };
      }
    }
    
    if (name === "get-pod-logs") {
      const { name: podName, namespace = "default" } = args as any;
      
      try {
        const response = await k8sApi.readNamespacedPodLog({ 
          name: podName, 
          namespace,
          tailLines: 100
        });

        return {
          content: [{
            type: "text",
            text: `📋 Logs for pod "${podName}" in namespace "${namespace}":\n\n${response}`
          }]
        };
      } catch (error: any) {
        return {
          content: [{
            type: "text",
            text: `❌ Failed to get logs: ${error.message}`
          }],
          isError: true
        };
      }
    }
    
    if (name === "delete-pod") {
      const { name: podName, namespace = "default" } = args as any;
      
      try {
        await k8sApi.deleteNamespacedPod({ name: podName, namespace });
        
        return {
          content: [{
            type: "text",
            text: `🗑️ Successfully deleted pod "${podName}" from namespace "${namespace}"`
          }]
        };
      } catch (error: any) {
        return {
          content: [{
            type: "text",
            text: `❌ Failed to delete pod: ${error.message}`
          }],
          isError: true
        };
      }
    }
    
    throw new Error(`Unknown tool: ${name}`);
  });
}
EOF

echo "✅ Created shared tool handlers"
```{{exec}}

## Add Prompt Handlers

Let's add prompt handlers for Kubernetes troubleshooting:

```bash
# Complete the shared handlers file with prompt support
cat >> src/handlers/k8s-handlers.ts << 'EOF'

// Prompt handlers
export function setupPromptHandlers(server: Server) {
  server.setRequestHandler(ListPromptsRequestSchema, async () => {
    return {
      prompts: [
        {
          name: "troubleshoot-pod",
          description: "Systematic approach to diagnosing pod problems",
          arguments: [
            {
              name: "podName",
              description: "Name of the pod to troubleshoot",
              required: true
            },
            {
              name: "namespace", 
              description: "Namespace of the pod",
              required: false
            }
          ]
        },
        {
          name: "optimize-resources",
          description: "Analyze and optimize resource usage",
          arguments: [
            {
              name: "namespace",
              description: "Namespace to analyze", 
              required: false
            }
          ]
        }
      ]
    };
  });

  server.setRequestHandler(GetPromptRequestSchema, async (request) => {
    const { name, arguments: args } = request.params;
    
    if (name === "troubleshoot-pod") {
      const { podName, namespace = "default" } = args || {};
      
      return {
        description: `Troubleshooting guide for pod ${podName} in namespace ${namespace}`,
        messages: [{
          role: "user",
          content: {
            type: "text",
            text: `Please help me troubleshoot the Kubernetes pod "${podName}" in namespace "${namespace}". \n\nFollow this systematic approach:\n1. Check pod status and phase\n2. Examine recent events\n3. Review container logs  \n4. Verify resource requests/limits\n5. Check network connectivity\n6. Validate persistent volume claims\n7. Review security contexts and RBAC\n\nProvide step-by-step diagnosis with specific kubectl commands and potential solutions for each issue you identify.`
          }
        }]
      };
    }
    
    if (name === "optimize-resources") {
      const { namespace = "default" } = args || {};
      
      return {
        description: `Resource optimization analysis for namespace ${namespace}`,
        messages: [{
          role: "user",
          content: {
            type: "text",
            text: `Please analyze the resource usage in Kubernetes namespace "${namespace}" and provide optimization recommendations.\n\nPlease examine:\n1. CPU and memory requests vs limits vs actual usage\n2. Pod resource efficiency and right-sizing opportunities\n3. Horizontal Pod Autoscaler configuration\n4. Resource quotas and limits\n5. Node resource allocation and capacity planning\n\nProvide specific recommendations with YAML examples for improvements.`
          }
        }]
      };
    }
    
    throw new Error(`Unknown prompt: ${name}`);
  });
}

// Setup all handlers on a server
export function setupMCPHandlers(server: Server) {
  setupResourceHandlers(server);
  setupToolHandlers(server);
  setupPromptHandlers(server);
}

export { k8sApi, appsApi };
EOF

echo "✅ Created shared prompt handlers and main setup function"
```{{exec}}

## Create Stdio MCP Server

Now let's create the main stdio server using our shared handlers:

```bash
# Create the stdio MCP server
cat > src/servers/k8s-mcp-server.ts << 'EOF'
import { Server } from "@modelcontextprotocol/sdk/server/index.js";
import { StdioServerTransport } from "@modelcontextprotocol/sdk/server/stdio.js";
import { setupMCPHandlers } from '../handlers/k8s-handlers.js';

// Create MCP server with shared configuration
function createMCPServer() {
  const server = new Server(
    {
      name: "kubernetes-mcp-server",
      version: "1.0.0"
    },
    {
      capabilities: {
        resources: {},
        tools: {},
        prompts: {}
      }
    }
  );

  // Setup all handlers using shared functions
  setupMCPHandlers(server);
  return server;
}

// Start the server with stdio transport
async function main() {
  try {
    const server = createMCPServer();
    const transport = new StdioServerTransport();
    await server.connect(transport);
    console.error("Kubernetes MCP Server (stdio) started successfully");
  } catch (error) {
    console.error("Failed to start MCP server:", error);
    process.exit(1);
  }
}

// Run if this file is executed directly
if (import.meta.url === `file://${process.argv[1]}`) {
  main().catch(console.error);
}

export { createMCPServer };
EOF

echo "✅ Created stdio MCP server"
```{{exec}}

## Create HTTP MCP Server

Let's also create an HTTP version for testing with MCP Inspector:

```bash
# Create the HTTP MCP server (simplified version for this step)
cat > src/servers/k8s-mcp-http-server.ts << 'EOF'
import express from 'express';
import { Server } from "@modelcontextprotocol/sdk/server/index.js";
import { setupMCPHandlers } from '../handlers/k8s-handlers.js';

// Create Express app for HTTP transport
const app = express();
const port = parseInt(process.env.MCP_PORT || '3001');

// Middleware setup
app.use(express.json({ limit: '50mb' }));
app.use(express.urlencoded({ extended: true }));

// Enable CORS for development
app.use((req, res, next) => {
  res.header('Access-Control-Allow-Origin', '*');
  res.header('Access-Control-Allow-Methods', 'GET, POST, PUT, DELETE, OPTIONS');
  res.header('Access-Control-Allow-Headers', 'Origin, X-Requested-With, Content-Type, Accept, Authorization');
  if (req.method === 'OPTIONS') {
    res.sendStatus(200);
  } else {
    next();
  }
});

// Create a new MCP server for each session
function createServerSession(): Server {
  const server = new Server(
    {
      name: "kubernetes-mcp-server",
      version: "1.0.0"
    },
    {
      capabilities: {
        resources: {},
        tools: {},
        prompts: {}
      }
    }
  );

  // Setup handlers using shared functions
  setupMCPHandlers(server);
  return server;
}

// Health check endpoint
app.get('/health', (req, res) => {
  res.json({ 
    status: 'healthy',
    transport: 'streamable-http',
    serverInfo: {
      name: 'kubernetes-mcp-server',
      version: '1.0.0'
    },
    timestamp: new Date().toISOString()
  });
});

// Handle MCP requests
app.post('/mcp', async (req, res) => {
  try {
    const server = createServerSession();
    const request = req.body;
    
    // Handle the request through MCP server
    let response;
    
    try {
      // Handle MCP protocol methods
      switch (request.method) {
        case 'initialize':
          response = {
            protocolVersion: '2024-11-05',
            capabilities: {
              resources: {},
              tools: {},
              prompts: {}
            },
            serverInfo: {
              name: 'kubernetes-mcp-server',
              version: '1.0.0'
            }
          };
          break;
        case 'resources/list':
          response = await server['_requestHandlers'].get('resources/list')?.(request);
          break;
        case 'resources/read':
          response = await server['_requestHandlers'].get('resources/read')?.(request);
          break;
        case 'tools/list':
          response = await server['_requestHandlers'].get('tools/list')?.(request);
          break;
        case 'tools/call':
          response = await server['_requestHandlers'].get('tools/call')?.(request);
          break;
        case 'prompts/list':
          response = await server['_requestHandlers'].get('prompts/list')?.(request);
          break;
        case 'prompts/get':
          response = await server['_requestHandlers'].get('prompts/get')?.(request);
          break;
        default:
          throw new Error(`Unknown method: ${request.method}`);
      }

      res.json({
        jsonrpc: '2.0',
        result: response,
        id: request.id
      });

    } catch (methodError: any) {
      res.status(400).json({
        jsonrpc: '2.0',
        error: {
          code: -32603,
          message: methodError.message
        },
        id: request.id || null
      });
    }

  } catch (error: any) {
    res.status(500).json({
      jsonrpc: '2.0', 
      error: {
        code: -32603,
        message: `Internal error: ${error.message}`
      },
      id: req.body?.id || null
    });
  }
});

// Start the HTTP server
async function main() {
  try {
    app.listen(port, () => {
      console.error(`Kubernetes MCP Server (HTTP) listening on port ${port}`);
      console.error(`Health check: http://localhost:${port}/health`);
      console.error(`MCP endpoint: http://localhost:${port}/mcp`);
    });
  } catch (error) {
    console.error("Failed to start HTTP MCP server:", error);
    process.exit(1);
  }
}

// Run if this file is executed directly
if (import.meta.url === `file://${process.argv[1]}`) {
  main().catch(console.error);
}
EOF

echo "✅ Created HTTP MCP server"
```{{exec}}

## Build and Test MCP Servers

Let's build and test both our stdio and HTTP servers:

```bash
# Compile TypeScript
npm run build

echo "=== Testing MCP Server Compilation ==="
# Test stdio server loading
node -e "
import('./dist/servers/k8s-mcp-server.js')
  .then(() => console.log('✅ Stdio MCP server loaded successfully'))
  .catch(e => console.error('❌ Error loading stdio server:', e.message))
"

# Test HTTP server loading  
node -e "
import('./dist/servers/k8s-mcp-http-server.js')
  .then(() => console.log('✅ HTTP MCP server loaded successfully'))
  .catch(e => console.error('❌ Error loading HTTP server:', e.message))
"
```{{exec}}

## Verify Kubernetes Integration

Let's test our Kubernetes connectivity for the MCP servers:

```bash
echo "=== Kubernetes Integration Test ==="
# Test basic Kubernetes API access
kubectl get nodes --no-headers | wc -l | xargs -I {} echo "Cluster has {} nodes"
kubectl get pods --all-namespaces --no-headers | wc -l | xargs -I {} echo "Total pods across all namespaces: {}"

# Verify permissions for MCP server operations
echo ""
echo "=== MCP Server Permissions Check ==="
kubectl auth can-i get pods && echo "✅ Can list pods"
kubectl auth can-i list nodes && echo "✅ Can list nodes" 
kubectl auth can-i create pods && echo "✅ Can create pods"
kubectl auth can-i get pods/log && echo "✅ Can get pod logs"
```{{exec}}

## Test HTTP Server

Let's quickly test the HTTP server:

```bash
# Start HTTP server in background for testing
echo "=== Starting HTTP MCP Server for Testing ==="
npm run start:http &
HTTP_PID=$!

# Wait for server to start
sleep 3

# Test health endpoint
echo "Testing health endpoint..."
curl -s http://localhost:3001/health | jq '.' || echo "Health check failed"

# Stop the test server
kill $HTTP_PID 2>/dev/null
wait $HTTP_PID 2>/dev/null

echo "✅ HTTP server test completed"
```{{exec}}

## Summary

Congratulations! You've built a robust MCP server with:

```bash
echo "==========================================="
echo "🚀 MCP Server Architecture Complete!"
echo "==========================================="
echo "📁 Shared Handlers: src/handlers/k8s-handlers.ts"
echo "🔌 Stdio Server: src/servers/k8s-mcp-server.ts"
echo "🌐 HTTP Server: src/servers/k8s-mcp-http-server.ts"
echo ""
echo "📋 Capabilities:"
echo "  🗂️  Resources: cluster-nodes, namespace-pods"  
echo "  🛠️  Tools: create-pod, get-pod-logs, delete-pod"
echo "  💡 Prompts: troubleshoot-pod, optimize-resources"
echo ""
echo "🔄 Transports: stdio (for Claude Desktop) + HTTP (for testing)"
echo "==========================================="
```{{exec}}

Perfect! Your MCP server is ready with both stdio and HTTP transports. In the next step, we'll connect it to AI applications and test it with MCP Inspector!

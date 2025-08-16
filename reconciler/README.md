# MCP Server Kubernetes Operator Tutorial

A comprehensive tutorial that teaches you to build a production-ready Kubernetes operator for managing Model Context Protocol (MCP) servers. This tutorial bridges AI tooling with cloud-native infrastructure through 11 hands-on steps.

## 🎯 What You'll Learn

This tutorial covers three essential areas:

### Part 1: MCP Fundamentals (Steps 1-5)
- Model Context Protocol architecture and core concepts
- Building MCP servers with TypeScript and the MCP SDK
- Connecting MCP servers to AI applications like Claude Desktop
- Understanding resources, tools, and prompts

### Part 2: Kubernetes Reconciliation (Steps 6-7)
- Custom Resource Definitions (CRDs) and kubebuilder setup
- Reconciliation patterns for MCP workloads

### Part 3: MCP Server Operator (Steps 8-11)
- Complete Kubernetes operator implementation
- Production-ready deployment management
- Security, monitoring, and scaling considerations
- RBAC and operational best practices

### Building the MCP Server

#### Prerequisites
- **Node.js**: Version 18+ required
- **npm**: For package management
- **Kubernetes cluster**: For testing MCP server functionality

### Project Configuration

```bash
mkdir -p workspace/mcp-lab
cd workspace/mcp-lab
npm init -y

npm install @modelcontextprotocol/sdk zod @kubernetes/client-node js-yaml express
npm install --save-dev typescript @types/node ts-node @types/express @types/js-yaml tsx

mkdir -p src/{servers,handlers,types,utils}
mkdir -p examples config
cd ../../
```

The project uses the following configuration from `package.json`:

```bash
cat << 'EOF' > workspace/mcp-lab/package.json
{
  "name": "mcp-kubernetes-lab",
  "version": "1.0.0",
  "description": "Kubernetes MCP Server Lab",
  "main": "dist/servers/k8s-mcp-server.js",
  "type": "module",
  "scripts": {
    "build": "tsc",
    "dev": "tsx src/servers/k8s-mcp-server.ts",
    "dev:http": "tsx src/servers/k8s-mcp-http-server.ts",
    "test": "node --test dist/test-client.js",
    "start": "node dist/servers/k8s-mcp-server.js",
    "start:http": "node dist/servers/k8s-mcp-http-server.js",
    "inspector": "npx @modelcontextprotocol/inspector dist/servers/k8s-mcp-server.js",
    "inspector-http": "npx @modelcontextprotocol/inspector http://localhost:3001/mcp",
    "clean": "rm -rf dist"
  },
  "keywords": [
    "mcp",
    "kubernetes",
    "ai",
    "model-context-protocol"
  ],
  "author": "MCP Tutorial",
  "license": "MIT",
  "dependencies": {
    "@kubernetes/client-node": "^1.3.0",
    "@modelcontextprotocol/sdk": "^1.17.3",
    "express": "^4.18.2",
    "js-yaml": "^4.1.0",
    "zod": "^3.25.76"
  },
  "devDependencies": {
    "@types/express": "^5.0.3",
    "@types/js-yaml": "^4.0.9",
    "@types/node": "^24.3.0",
    "ts-node": "^10.9.2",
    "tsx": "^4.20.4",
    "typescript": "^5.9.2"
  },
  "engines": {
    "node": ">=18.0.0"
  }
}
EOF
```

#### TypeScript Configuration

The project uses modern TypeScript configuration optimized for Node.js and ESM modules:

```bash
cat << 'EOF' > workspace/mcp-lab/tsconfig.json
{
  "compilerOptions": {
    "target": "ES2022",
    "module": "ESNext",
    "moduleResolution": "node",
    "esModuleInterop": true,
    "allowSyntheticDefaultImports": true,
    "strict": true,
    "skipLibCheck": true,
    "forceConsistentCasingInFileNames": true,
    "outDir": "./dist",
    "rootDir": "./src"
  },
  "include": ["src/**/*"],
  "exclude": ["node_modules", "dist"],
  "ts-node": {
    "esm": true,
    "experimentalSpecifierResolution": "node"
  }
}
EOF
```

### MCP Server Features

The implemented MCP server provides comprehensive Kubernetes integration with:

#### Resources
- **`cluster-nodes`**: Real-time cluster node information with capacity and status
- **`namespace-pods`**: Dynamic pod listing with parameterized namespace support

#### Tools
- **`create-pod`**: Create Kubernetes pods with proper resource limits and labels
- **`get-pod-logs`**: Retrieve pod logs with configurable line limits
- **`delete-pod`**: Safely delete pods with proper error handling

#### Prompts
- **`troubleshoot-pod`**: Systematic pod troubleshooting workflow
- **`optimize-resources`**: Resource optimization analysis and recommendations

### Transport Support

#### stdio Transport (`k8s-mcp-server.ts`)
Optimized for desktop applications like Claude Desktop:
- Direct process communication
- Minimal overhead
- Perfect for local development

#### Streamable HTTP Transport (`k8s-mcp-http-server.ts`)
Designed for modern web applications and HTTP-based integration:
- RESTful HTTP endpoints with JSON-RPC 2.0
- Session-based communication
- Stateless request/response model
- CORS support for browser clients

### Development Workflow

1. **Install Dependencies**: `npm install`
2. **Build Project**: `npm run build`
3. **Development**: `npm run dev` (stdio) or `npm run dev:http` (HTTP)
4. **Test**: `npm run inspector` or `npm run inspector-http`
5. **Production**: `npm run start` or `npm run start:http`


### Step 4: Complete MCP Server Implementation

### Types 

```bash
cat << 'EOF' > workspace/mcp-lab/src/types/index.ts
import { z } from 'zod';

// Common Kubernetes types
export const KubernetesResourceSchema = z.object({
  apiVersion: z.string(),
  kind: z.string(),
  metadata: z.object({
    name: z.string(),
    namespace: z.string().optional(),
    labels: z.record(z.string()).optional(),
    annotations: z.record(z.string()).optional(),
  }),
});

// MCP Server configuration
export const MCPServerConfigSchema = z.object({
  name: z.string(),
  version: z.string(),
  description: z.string().optional(),
  transport: z.enum(['stdio', 'http', 'streamable-http']),
});

export type KubernetesResource = z.infer<typeof KubernetesResourceSchema>;
export type MCPServerConfig = z.infer<typeof MCPServerConfigSchema>;
EOF
```

#### Shared MCP Server Handlers (`src/handlers/k8s-handlers.ts`)

```bash
cat << 'EOF' > workspace/mcp-lab/src/handlers/k8s-handlers.ts
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
        const response = await k8sApi.readNamespacedPodLog({ name: podName, namespace });

        return {
          content: [{
            type: "text",
            text: `📋 Logs for pod "${podName}" in namespace "${namespace}":\n\n${(response as any).body || response}`
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
```

#### Refactored Main MCP Server (`src/servers/k8s-mcp-server.ts`)

```bash
cat << 'EOF' > workspace/mcp-lab/src/servers/k8s-mcp-server.ts
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
```

#### Streamable HTTP MCP Server (`src/servers/k8s-mcp-http-server.ts`)

```bash
cat << 'EOF' > workspace/mcp-lab/src/servers/k8s-mcp-http-server.ts
import express from 'express';
import { Server } from "@modelcontextprotocol/sdk/server/index.js";
import { createMCPServer } from './k8s-mcp-server.js';
import { setupMCPHandlers } from '../handlers/k8s-handlers.js';

// Create Express app for HTTP transport
const app = express();

// Middleware setup
app.use(express.json({ limit: '50mb' }));
app.use(express.urlencoded({ extended: true }));

// Enable CORS for development (adjust for production)
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

// Store active MCP server sessions
const activeSessions = new Map<string, { server: Server; createdAt: Date }>();

// Session cleanup - remove sessions older than 1 hour
setInterval(() => {
  const now = new Date();
  for (const [sessionId, session] of activeSessions.entries()) {
    if (now.getTime() - session.createdAt.getTime() > 60 * 60 * 1000) {
      activeSessions.delete(sessionId);
      console.log(`Cleaned up expired session: ${sessionId}`);
    }
  }
}, 5 * 60 * 1000); // Check every 5 minutes

// Create a new MCP server session
function createServerSession(): { server: Server; sessionId: string } {
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
  
  const sessionId = `session_${Date.now()}_${Math.random().toString(36).substr(2, 9)}`;
  activeSessions.set(sessionId, { server, createdAt: new Date() });
  
  return { server, sessionId };
}

// Health check endpoint
app.get('/health', (req, res) => {
  res.json({ 
    status: 'healthy',
    transport: 'streamable-http',
    activeSessions: activeSessions.size,
    serverInfo: {
      name: 'kubernetes-mcp-server',
      version: '1.0.0'
    },
    timestamp: new Date().toISOString()
  });
});

// Get server capabilities
app.get('/capabilities', (req, res) => {
  res.json({
    protocolVersion: '2024-11-05',
    capabilities: {
      resources: {
        subscribe: false,
        listChanged: false
      },
      tools: {
        listChanged: false
      },
      prompts: {
        listChanged: false
      },
      experimental: {}
    },
    serverInfo: {
      name: 'kubernetes-mcp-server',
      version: '1.0.0'
    }
  });
});

// Initialize new session
app.post('/initialize', (req, res) => {
  try {
    const { server, sessionId } = createServerSession();
    
    res.json({
      protocolVersion: '2024-11-05',
      capabilities: {
        resources: {},
        tools: {},
        prompts: {}
      },
      serverInfo: {
        name: 'kubernetes-mcp-server',
        version: '1.0.0'
      },
      sessionId: sessionId,
      instructions: 'Session initialized. Use the sessionId in subsequent requests.'
    });
  } catch (error: any) {
    res.status(500).json({ 
      error: 'Failed to initialize session',
      message: error.message 
    });
  }
});

// Handle MCP requests with session support
app.post('/mcp/:sessionId?', async (req, res) => {
  try {
    const sessionId = req.params.sessionId;
    let server: Server;
    
    if (sessionId && activeSessions.has(sessionId)) {
      server = activeSessions.get(sessionId)!.server;
    } else {
      // Create new session if none provided or invalid
      const newSession = createServerSession();
      server = newSession.server;
      
      // Include new session ID in response headers
      res.header('X-Session-ID', newSession.sessionId);
    }

    const request = req.body;
    
    // Validate JSON-RPC format
    if (!request.jsonrpc || request.jsonrpc !== '2.0') {
      return res.status(400).json({
        jsonrpc: '2.0',
        error: {
          code: -32600,
          message: 'Invalid Request: missing or invalid jsonrpc version'
        },
        id: request.id || null
      });
    }

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
          code: -32601,
          message: `Method not found: ${request.method}`,
          data: methodError.message
        },
        id: request.id
      });
    }
    
  } catch (error: any) {
    console.error('Error handling MCP request:', error);
    res.status(500).json({
      jsonrpc: '2.0',
      error: {
        code: -32603,
        message: 'Internal error',
        data: error.message
      },
      id: req.body?.id || null
    });
  }
});

// Generic MCP endpoint (creates session automatically)
app.post('/mcp', async (req, res) => {
  // Redirect to session-based endpoint
  req.url = '/mcp/';
  return app._router.handle(req, res);
});

// List active sessions (for debugging)
app.get('/sessions', (req, res) => {
  const sessions = Array.from(activeSessions.entries()).map(([id, session]) => ({
    sessionId: id,
    createdAt: session.createdAt,
    age: Date.now() - session.createdAt.getTime()
  }));
  
  res.json({ 
    count: sessions.length,
    sessions 
  });
});

// Clean up specific session
app.delete('/sessions/:sessionId', (req, res) => {
  const { sessionId } = req.params;
  
  if (activeSessions.has(sessionId)) {
    activeSessions.delete(sessionId);
    res.json({ message: `Session ${sessionId} terminated` });
  } else {
    res.status(404).json({ error: 'Session not found' });
  }
});

// Error handling middleware
app.use((error: any, req: express.Request, res: express.Response, next: express.NextFunction) => {
  console.error('Express error:', error);
  res.status(500).json({
    jsonrpc: '2.0',
    error: {
      code: -32603,
      message: 'Internal server error',
      data: error.message
    },
    id: null
  });
});

// Start HTTP server
const PORT = process.env.PORT || 3001;
const server = app.listen(PORT, () => {
  console.log(`🚀 Kubernetes MCP HTTP Server running on http://localhost:${PORT}`);
  console.log(`🔌 Transport: Streamable HTTP (MCP 2024-11-05)`);
  console.log(`🎯 Endpoints:`);
  console.log(`   POST /mcp           - Main MCP endpoint (auto-session)`);
  console.log(`   POST /mcp/:session  - Session-specific MCP endpoint`);
  console.log(`   POST /initialize    - Initialize new session`);
  console.log(`   GET  /capabilities  - Server capabilities`);
  console.log(`   GET  /health       - Health check`);
  console.log(`   GET  /sessions     - List active sessions`);
  console.log(`\n🔍 Test with MCP Inspector:`);
  console.log(`   npx @modelcontextprotocol/inspector http://localhost:${PORT}/mcp`);
});

export { app, server };
EOF
```

### Step 5: Claude Desktop Configuration

#### Claude Desktop Configuration

For integrating with Claude Desktop, update your `~/.claude-desktop-config.json`:

```json
{
  "mcpServers": {
    "kubernetes": {
      "command": "node", 
      "args": ["/Users/saghili/personal/killercoda/reconciler/workspace/mcp-lab/dist/servers/k8s-mcp-server.js"],
      "env": {
        "KUBECONFIG": "/Users/saghili/.kube/config"
      }
    }
  }
}
```

**Important Notes**: 
- Use `k8s-mcp-server.js` (stdio) for Claude Desktop, NOT `k8s-mcp-http-server.js`
- Use absolute paths for both the server file and KUBECONFIG  
- The HTTP server is for web integrations and MCP Inspector testing only

### Steps 7-12: Complete Kubernetes Operator Implementation

#### Project Setup
```bash
mkdir -p workspace/mcp-operator
cd workspace/mcp-operator

kubebuilder init --domain example.com --repo example.com
kubebuilder create api --group mcp --version v1alpha1 --kind MCPServer --controller --resource
```

#### MCPServer Types (`api/v1alpha1/mcpserver_types.go`)
```bash
cat << 'EOF' > workspace/mcp-operator/api/v1alpha1/mcpserver_types.go
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
	MCPServerFinalizer = "example.com/finalizer"
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

#### Main Controller (`internal/controller/mcpserver_controller.go`)

```bash
cat << 'EOF' > workspace/mcp-operator/internal/controller/mcpserver_controller.go
/*
Copyright 2025.

Licensed under the Apache License, Version 2.0 (the "License");
you may not use this file except in compliance with the License.
You may obtain a copy of the License at

    http://www.apache.org/licenses/LICENSE-2.0

Unless required by applicable law or agreed to in writing, software
distributed under the License is distributed on an "AS IS" BASIS,
WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
See the License for the specific language governing permissions and
limitations under the License.
*/

package controller

import (
	"context"
	"fmt"
	"time"

	appsv1 "k8s.io/api/apps/v1"
	corev1 "k8s.io/api/core/v1"
	"k8s.io/apimachinery/pkg/api/errors"
	metav1 "k8s.io/apimachinery/pkg/apis/meta/v1"
	"k8s.io/apimachinery/pkg/runtime"
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

	// Reconcile Service
	service, err := r.reconcileService(ctx, &mcpServer)
	if err != nil {
		logger.Error(err, "Failed to reconcile Service")
		r.updateStatus(ctx, &mcpServer, mcpv1alpha1.MCPServerPhaseFailed, "Failed to reconcile service")
		return ctrl.Result{}, err
	}

	// Reconcile Deployment
	deployment, err := r.reconcileDeployment(ctx, &mcpServer)
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

	// Additional cleanup logic can go here
	logger.Info("MCPServer cleanup completed", "mcpserver", mcpServer.Name)
	return nil
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
		labels := r.labelsForMCPServer(mcpServer)
		service.Spec = corev1.ServiceSpec{
			Selector: labels,
			Ports: []corev1.ServicePort{
				{
					Name:       "mcp",
					Port:       mcpServer.GetPort(),
					TargetPort: intstr.FromInt(int(mcpServer.GetPort())),
					Protocol:   corev1.ProtocolTCP,
				},
			},
			Type: corev1.ServiceTypeClusterIP,
		}
		return nil
	})

	if err != nil {
		return nil, fmt.Errorf("failed to reconcile service: %w", err)
	}

	log.FromContext(ctx).Info("Service reconciled", "operation", operationResult, "service", service.Name)
	return service, nil
}

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
		labels := r.labelsForMCPServer(mcpServer)
		replicas := mcpServer.GetReplicas()
		port := mcpServer.GetPort()

		deployment.Spec = appsv1.DeploymentSpec{
			Replicas: &replicas,
			Selector: &metav1.LabelSelector{
				MatchLabels: labels,
			},
			Template: corev1.PodTemplateSpec{
				ObjectMeta: metav1.ObjectMeta{
					Labels: labels,
				},
				Spec: corev1.PodSpec{
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
							Env: []corev1.EnvVar{
								{Name: "MCP_TRANSPORT", Value: mcpServer.GetTransport()},
								{Name: "MCP_PORT", Value: fmt.Sprintf("%d", port)},
								{Name: "MCP_SERVER_NAME", Value: mcpServer.Name},
							},
							ReadinessProbe: &corev1.Probe{
								ProbeHandler: corev1.ProbeHandler{
									HTTPGet: &corev1.HTTPGetAction{
										Path: "/health",
										Port: intstr.FromInt(int(port)),
									},
								},
								InitialDelaySeconds: 5,
								PeriodSeconds:       5,
								FailureThreshold:    3,
							},
						},
					},
				},
			},
		}

		// Set resource requirements if specified
		if mcpServer.Spec.Resources != nil {
			deployment.Spec.Template.Spec.Containers[0].Resources = corev1.ResourceRequirements{
				Requests: mcpServer.Spec.Resources.Requests,
				Limits:   mcpServer.Spec.Resources.Limits,
			}
		}

		return nil
	})

	if err != nil {
		return nil, fmt.Errorf("failed to reconcile deployment: %w", err)
	}

	log.FromContext(ctx).Info("Deployment reconciled", "operation", operationResult, "deployment", deployment.Name)
	return deployment, nil
}

func (r *MCPServerReconciler) labelsForMCPServer(mcpServer *mcpv1alpha1.MCPServer) map[string]string {
	return map[string]string{
		"app.kubernetes.io/name":       "mcp-server",
		"app.kubernetes.io/instance":   mcpServer.Name,
		"app.kubernetes.io/component":  "server",
		"app.kubernetes.io/managed-by": "mcp-operator",
		"example.com/transport":    mcpServer.GetTransport(),
	}
}

func (r *MCPServerReconciler) updateStatus(ctx context.Context, mcpServer *mcpv1alpha1.MCPServer, phase mcpv1alpha1.MCPServerPhase, message string) {
	mcpServer.Status.Phase = phase
	mcpServer.Status.ObservedGeneration = mcpServer.Generation
	
	if phase == mcpv1alpha1.MCPServerPhaseFailed {
		mcpServer.SetCondition(mcpv1alpha1.ConditionReady, "False", "Failed", message)
	}
	
	if err := r.Status().Update(ctx, mcpServer); err != nil {
		log.FromContext(ctx).Error(err, "Failed to update MCPServer status")
	}
}

func (r *MCPServerReconciler) updateStatusFromResources(ctx context.Context, mcpServer *mcpv1alpha1.MCPServer, deployment *appsv1.Deployment, service *corev1.Service) (ctrl.Result, error) {
	logger := log.FromContext(ctx)
	
	// Update status based on deployment
	mcpServer.Status.Replicas = deployment.Status.Replicas
	mcpServer.Status.ReadyReplicas = deployment.Status.ReadyReplicas
	mcpServer.Status.ObservedGeneration = mcpServer.Generation
	
	// Determine phase based on deployment status
	if deployment.Status.ReadyReplicas == mcpServer.GetReplicas() {
		mcpServer.Status.Phase = mcpv1alpha1.MCPServerPhaseReady
		mcpServer.SetCondition(mcpv1alpha1.ConditionReady, "True", "Ready", "MCPServer is ready")
		mcpServer.Status.Endpoint = fmt.Sprintf("http://%s.%s.svc.cluster.local:%d", service.Name, service.Namespace, mcpServer.GetPort())
	} else {
		mcpServer.Status.Phase = mcpv1alpha1.MCPServerPhasePending
		mcpServer.SetCondition(mcpv1alpha1.ConditionReady, "False", "Pending", "Waiting for deployment to be ready")
	}

	if err := r.Status().Update(ctx, mcpServer); err != nil {
		logger.Error(err, "Failed to update MCPServer status")
		return ctrl.Result{}, err
	}

	// Requeue if not ready
	if mcpServer.Status.Phase != mcpv1alpha1.MCPServerPhaseReady {
		return ctrl.Result{RequeueAfter: 30 * time.Second}, nil
	}

	return ctrl.Result{}, nil
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
```

#### Deployment Management (`controllers/deployment.go`)
```go
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
		"example.com/transport":    mcpServer.GetTransport(),
	}
}
```

## 📋 Sample Resources

#### Basic MCPServer
```bash
cat << 'EOF' > workspace/basic-mcpserver.yaml
apiVersion: mcp.example.com/v1alpha1
kind: MCPServer
metadata:
  name: basic-mcpserver
  namespace: default
  labels:
    environment: development
spec:
  image: "mcp-k8s-server:latest"  # Your built Docker image
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
```

#### Advanced Production MCPServer
```bash
cat << 'EOF' > workspace/advanced-mcpserver.yaml
apiVersion: mcp.example.com/v1alpha1
kind: MCPServer
metadata:
  name: advanced-mcpserver
  namespace: default
  labels:
    environment: production
    team: ai-platform
spec:
  image: "mcp-k8s-server:latest"  # Your built Docker image
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
```

## 🚀 Quick Start Guide

### Local Development Setup

#### Prerequisites
- **Kubernetes Cluster**: kind, minikube, Docker Desktop, or remote cluster
- **Node.js**: Version 18+ for MCP server development
- **Go**: Version 1.21+ for operator development  
- **kubectl**: Configured to access your cluster
- **Docker**: For building container images

#### Install Development Tools
```bash
cat << EOF | bash
# Install MCP Inspector for testing
npm install -g @modelcontextprotocol/inspector

# Install kind for local Kubernetes
go install sigs.k8s.io/kind@latest

# Install Kubebuilder
curl -L -o kubebuilder "https://go.kubebuilder.io/dl/latest/\$(go env GOOS)/\$(go env GOARCH)"
chmod +x kubebuilder && sudo mv kubebuilder /usr/local/bin/

# Create local cluster
kind create cluster --name mcp-operator-demo

# Verify setup
kubectl cluster-info
node --version
go version
kubebuilder version
EOF
```

### Build and Test MCP Server

```bash
# Build the MCP server from the actual implementation
cd workspace/mcp-lab/
npm install  # Install dependencies
npm run build  # Compile TypeScript to JavaScript

# Test with MCP Inspector (stdio version)
npm run inspector

# Or test the HTTP version
npm run dev:http &
npm run inspector-http

# Test client communication
node dist/test-client.js

# Verify Kubernetes connectivity
kubectl cluster-info
```

### Containerize MCP Server

Create a Docker image from your MCP server for deployment:

#### Create Dockerfile
```bash
cat << 'EOF' > workspace/mcp-lab/Dockerfile
FROM node:18-alpine

# Create app directory
WORKDIR /app

# Copy package files
COPY package*.json ./

# Install dependencies
RUN npm install

# Copy source code
COPY . .

# Build the project
RUN npm run build

# Expose the port
EXPOSE 3001

# Set environment variables
ENV NODE_ENV=production
ENV MCP_TRANSPORT=streamable-http
ENV MCP_PORT=3001

# Create non-root user (use different ID to avoid conflicts)
RUN addgroup -g 1001 mcp && adduser -u 1001 -G mcp -s /bin/sh -D mcp

# Change to non-root user
USER mcp

# Start the HTTP server
CMD ["node", "dist/servers/k8s-mcp-http-server.js"]
EOF
```

#### Build and Load Docker Image
```bash
# Build the Docker image
cd workspace/mcp-lab/
docker build -t mcp-k8s-server:latest .

# For kind clusters, load the image
kind load docker-image mcp-k8s-server:latest

# For other clusters, push to your registry
# docker tag mcp-k8s-server:latest your-registry/mcp-k8s-server:latest
# docker push your-registry/mcp-k8s-server:latest

# Verify image
docker images | grep mcp-k8s-server
```

### Deploy the Operator

```bash
# Initialize and build the operator
cd workspace
kubebuilder init --domain example.com --repo example.com --project-name mcp-operator
cd mcp-operator
kubebuilder create api --group mcp --version v1alpha1 --kind MCPServer --controller --resource

# Update dependencies and generate manifests
go mod tidy
make generate && make manifests

# Install CRDs in cluster
make install

# Build the operator
make build

# Run operator locally (in background)
make run &

# Deploy sample MCPServer with your built image
cat << 'EOF' > ../basic-mcpserver.yaml
apiVersion: mcp.example.com/v1alpha1
kind: MCPServer
metadata:
  name: basic-mcpserver
  namespace: default
  labels:
    environment: development
spec:
  image: "mcp-k8s-server:latest"  # Your built image
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

kubectl apply -f ../basic-mcpserver.yaml

# Monitor deployment
kubectl get mcpservers
kubectl get pods -l app.kubernetes.io/name=mcp-server
kubectl describe mcpserver basic-mcpserver

# Test MCP server functionality
kubectl port-forward service/basic-mcpserver 3001:3001 &
curl -X POST http://localhost:3001/mcp \
  -H "Content-Type: application/json" \
  -d '{"jsonrpc":"2.0","method":"tools/list","params":{},"id":1}'
```

### Production Deployment

For production environments, deploy the operator as a deployment:

```bash
# Build operator image
cd workspace/mcp-operator
make docker-build IMG=your-registry/mcp-operator:latest
docker push your-registry/mcp-operator:latest

# Deploy operator to cluster
make deploy IMG=your-registry/mcp-operator:latest

# Create production MCPServer
cat << 'EOF' > ../production-mcpserver.yaml
apiVersion: mcp.example.com/v1alpha1
kind: MCPServer
metadata:
  name: production-mcpserver
  namespace: mcp-system
  labels:
    environment: production
    team: ai-platform
spec:
  image: "your-registry/mcp-k8s-server:v1.0.0"
  transport: streamable-http
  port: 3001
  replicas: 3
  config:
    MCP_SERVER_NAME: "production-k8s-server"
    LOG_LEVEL: "warn"
    ENABLE_METRICS: "true"
  resources:
    requests:
      cpu: "100m"
      memory: "128Mi"
    limits:
      cpu: "500m"
      memory: "512Mi"
  securityContext:
    runAsNonRoot: true
    runAsUser: 1001
    runAsGroup: 1001
    allowPrivilegeEscalation: false
    capabilities:
      drop:
        - ALL
    readOnlyRootFilesystem: true
EOF

kubectl create namespace mcp-system
kubectl apply -f ../production-mcpserver.yaml
```

## 🎯 Key Learning Outcomes

By completing this tutorial, you'll have:

- ✅ **Built Production MCP Servers**: Complete TypeScript implementation with Kubernetes integration
- ✅ **Mastered Kubernetes Operators**: Full controller implementation with reconciliation patterns
- ✅ **Implemented CRDs**: Comprehensive custom resource with validation and status reporting
- ✅ **Applied Security Best Practices**: RBAC, pod security, and secrets management
- ✅ **Created Deployment Pipelines**: CI/CD, testing, and production deployment strategies
- ✅ **Built AI Infrastructure**: Bridge between AI applications and cloud-native systems

## 📊 Architecture Summary

![k8s-mcp-architecture](assets/k8s-mcp-architecture.svg)

### Operator Control Loop

![k8s-mcp-operator-control-loop](assets/k8s-mcp-controller-loop.svg)

### Component Interaction Flow

![k8s-mcp-interaction-model](assets/k8s-mcp-interaction-model.svg)

## 🔧 Essential Commands

### MCP Development
```bash
# Build and test MCP server
cd workspace/mcp-lab/
npm run build
npm run dev      # stdio server
npm run dev:http # HTTP server
npm run test

# Build Docker image
docker build -t mcp-k8s-server:latest .
kind load docker-image mcp-k8s-server:latest  # For kind clusters

# MCP Inspector testing
npm run inspector       # stdio server
npm run inspector-http  # HTTP server

# Test MCP protocol with HTTP server
curl -X POST http://localhost:3001/mcp \
  -H "Content-Type: application/json" \
  -d '{"jsonrpc":"2.0","method":"tools/list","params":{},"id":1}'

# Test specific Kubernetes operations
curl -X POST http://localhost:3001/mcp \
  -H "Content-Type: application/json" \
  -d '{"jsonrpc":"2.0","method":"tools/call","params":{"name":"create-pod","arguments":{"name":"test-pod","image":"nginx:alpine"}},"id":2}'
```

### Kubernetes Operator
```bash
# Development lifecycle
make generate        # Generate code from APIs
make manifests      # Generate CRD/RBAC manifests
make install        # Install CRDs in cluster
make run           # Run controller locally
make build         # Build manager binary

# Testing and deployment
make test          # Run unit tests
make docker-build  # Build container image
make deploy        # Deploy to cluster

# Resource management
kubectl get mcpservers
kubectl describe mcpserver my-server
kubectl get pods -l app.kubernetes.io/name=mcp-server
kubectl logs -f deployment/mcp-operator-controller-manager

# Test scaling
kubectl patch mcpserver basic-mcpserver --type='merge' -p='{"spec":{"replicas":3}}'
```

## 🏭 Production Deployment

### Security Hardening
- **RBAC**: Minimal privilege service accounts
- **Pod Security**: Non-root execution, read-only filesystem
- **Network Policies**: Restricted pod-to-pod communication
- **Secrets Management**: Kubernetes secrets with rotation

### Monitoring & Observability
- **Metrics**: Prometheus integration with operator and MCP server metrics
- **Logging**: Structured logging with centralized aggregation
- **Alerting**: Health checks, failure detection, and performance alerts
- **Dashboards**: Grafana dashboards for operational visibility

### High Availability
- **Operator HA**: Multiple controller replicas with leader election
- **MCP Server HA**: Multi-replica deployments with load balancing
- **Backup & Recovery**: Persistent volume snapshots and configuration backups

## 🚨 Troubleshooting Guide

### Common Setup Issues
```bash
# Verify installations
node --version    # Should be 18+ (required for MCP server)
go version       # Should be 1.21+ (required for operator)
kubectl version  # Should connect to cluster
kubebuilder version # Should be installed for operator development

# Test MCP server dependencies
cd workspace/mcp-lab/
npm list @modelcontextprotocol/sdk
npm list @kubernetes/client-node

# Check cluster access
kubectl cluster-info
kubectl auth can-i create customresourcedefinitions

# Test MCP Inspector
npm list -g @modelcontextprotocol/inspector
```

### Image Pull Issues (ImagePullBackOff)
```bash
# For kind clusters, ensure image is loaded
kind load docker-image mcp-k8s-server:latest

# Verify image is available in cluster
docker exec kind-control-plane crictl images | grep mcp

# Check pod events for specific errors
kubectl describe pod <pod-name>

# The controller automatically sets imagePullPolicy: IfNotPresent
# for locally built images
```

### Kubernetes API Client Issues
```bash
# If you see API call errors, ensure you're using object parameters:
# OLD (incorrect): k8sApi.listNamespacedPod(namespace)
# NEW (correct):   k8sApi.listNamespacedPod({ namespace })

# Update your handlers/k8s-handlers.ts accordingly
```

### Operator Development Issues
```bash
# Regenerate after API changes
make generate && make manifests

# CRD issues - clean slate approach
make uninstall && make install
kubectl get crd mcpservers.mcp.example.com

# Controller debugging
kubectl get mcpservers
kubectl describe mcpserver <name>
kubectl get pods -l app.kubernetes.io/name=mcp-server
kubectl logs -f deployment/mcp-operator-controller-manager

# Check operator logs when running locally
make run
# Look for reconciliation errors and status updates

# Port conflicts when restarting operator
lsof -i :8081 | grep -v PID | awk '{print $2}' | xargs kill -9 2>/dev/null || true
```

### MCP Server Connectivity Issues
```bash
# Test MCP server endpoints
kubectl port-forward service/basic-mcpserver 3001:3001 &

# Test tools endpoint
curl -X POST http://localhost:3001/mcp \
  -H "Content-Type: application/json" \
  -d '{"jsonrpc":"2.0","method":"tools/list","params":{},"id":1}'

# Test resources endpoint
curl -X POST http://localhost:3001/mcp \
  -H "Content-Type: application/json" \
  -d '{"jsonrpc":"2.0","method":"resources/list","params":{},"id":2}'

# Check health endpoint
curl http://localhost:3001/health

# If using Claude Desktop, use stdio transport (not HTTP)
# Update your claude_desktop_config.json to use k8s-mcp-server.js
```

## 🔮 What's Next?

After completing this tutorial:

- **Extend the Operator**: Add autoscaling, multi-tenancy, and advanced features
- **Build MCP Applications**: Create AI applications that leverage your operator
- **Contribute to MCP Ecosystem**: Develop additional MCP servers and tools
- **Production Deployment**: Deploy to real clusters with full observability
- **Advanced Patterns**: Explore GitOps, service mesh, and cloud-native AI patterns

---

**🚀 Ready to build the future of AI infrastructure?**

Start with [Step 1: Introduction to MCP](step1/text.md) and dive into this comprehensive hands-on tutorial that transforms you into an expert in AI-native cloud infrastructure!

*This tutorial bridges the gap between AI innovation and production-ready infrastructure, making MCP servers first-class citizens in the Kubernetes ecosystem.*
# Step 2: MCP Building Blocks - Servers, Clients, and Components

Now let's explore the three core MCP primitives in detail and understand how they work together.

## MCP Resources

Resources provide structured data to AI applications. They're similar to REST API GET endpoints:

```typescript
// Example: Kubernetes cluster resource
server.registerResource(
  "cluster-info",
  "k8s://cluster/info",
  {
    title: "Cluster Information",
    description: "Current Kubernetes cluster status",
    mimeType: "application/json"
  },
  async (uri) => ({
    contents: [{
      uri: uri.href,
      text: JSON.stringify({
        nodes: await getNodeCount(),
        pods: await getPodCount(),
        version: await getClusterVersion()
      })
    }]
  })
);
```

Resources are **read-only** and should be **idempotent**. They provide context but don't perform actions.

## MCP Tools  

Tools enable AI applications to perform actions. They're like REST API POST endpoints:

```typescript
// Example: Pod creation tool
server.registerTool(
  "create-pod",
  {
    title: "Create Pod",
    description: "Create a new pod in the cluster",
    inputSchema: {
      name: z.string(),
      image: z.string(),
      namespace: z.string().default("default")
    }
  },
  async ({ name, image, namespace }) => {
    const pod = await k8sApi.createNamespacedPod(namespace, {
      metadata: { name },
      spec: {
        containers: [{ name, image }]
      }
    });
    
    return {
      content: [{
        type: "text",
        text: `Created pod ${name} in namespace ${namespace}`
      }]
    };
  }
);
```

Tools can have **side effects** and perform **mutations**.

## MCP Prompts

Prompts are reusable templates that guide AI interactions:

```typescript
// Example: Kubernetes troubleshooting prompt
server.registerPrompt(
  "troubleshoot-pod",
  {
    title: "Troubleshoot Pod Issues",
    description: "Systematically diagnose pod problems",
    argsSchema: {
      podName: z.string(),
      namespace: z.string().default("default")
    }
  },
  ({ podName, namespace }) => ({
    messages: [{
      role: "user",
      content: {
        type: "text",
        text: `Please troubleshoot the pod "${podName}" in namespace "${namespace}". Check:
1. Pod status and events
2. Container logs
3. Resource requests/limits
4. Network connectivity
5. Storage issues

Provide step-by-step diagnosis and remediation suggestions.`
      }
    }]
  })
);
```

## Protocol Communication

All MCP communication uses **JSON-RPC 2.0** over various transports:

1. **stdio** - For command-line tools and local integrations
2. **HTTP/SSE** - For remote servers (legacy)
3. **Streamable HTTP** - For modern remote servers

Let's examine a real MCP server structure:

```bash
# Create a simple directory structure for our MCP exploration
mkdir -p /tmp/mcp-exploration
cd /tmp/mcp-exploration

# Create a basic MCP server structure
cat > package.json << 'EOF'
{
  "name": "k8s-mcp-server",
  "version": "1.0.0",
  "type": "module",
  "dependencies": {
    "@modelcontextprotocol/sdk": "^1.0.0",
    "zod": "^3.22.0"
  }
}
EOF

echo "Created basic MCP server package structure"
```{{exec}}

## Understanding MCP Sessions

MCP servers maintain sessions with clients through:

```typescript
// Session lifecycle
1. Initialize → Capability negotiation
2. List resources/tools/prompts → Discovery  
3. Read/call operations → Active usage
4. Close → Cleanup
```

Each session is **stateful** and maintains context throughout the interaction.

## Real-World MCP Examples

Let's look at some production MCP servers:

```bash
# Check out popular MCP servers
echo "Popular MCP Servers:"
echo "- GitHub: Automated code operations"
echo "- PostgreSQL: Database queries"
echo "- Slack: Messaging operations"
echo "- Kubernetes: Cluster management"
echo "- Filesystem: File operations"
```{{exec}}

## Next Steps

In the next step, we'll set up our development environment and start building our first MCP server!
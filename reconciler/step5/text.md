# Step 5: Connecting MCP Servers to LLMs

Now let's connect our MCP server to AI applications! We'll test it with the MCP Inspector and then configure it for use with Claude Desktop.

## Test with MCP Inspector

The MCP Inspector provides a web interface to test MCP servers:

```bash
cd /workspace/mcp-lab

# Start the MCP Inspector in the background
npx @modelcontextprotocol/inspector dist/servers/k8s-mcp-server.js &

echo "MCP Inspector is starting..."
echo "Note: In a real environment, this would open a browser at http://localhost:3000"
echo "The inspector provides a UI to test MCP resources, tools, and prompts"
```{{exec}}

[INSPECTOR]({{TRAFFIC_HOST1_3000}})
[INSPECTOR]({{TRAFFIC_HOST1_6274}})

## Create Claude Desktop Configuration

Let's create a configuration file for Claude Desktop:

```bash
# Create Claude Desktop configuration
mkdir -p /tmp/claude-desktop-config

cat > /tmp/claude-desktop-config/claude_desktop_config.json << 'EOF'
{
  "mcpServers": {
    "kubernetes": {
      "command": "node", 
      "args": ["/workspace/mcp-lab/dist/servers/k8s-mcp-server.js"],
      "env": {
        "KUBECONFIG": "/root/.kube/config"
      }
    }
  }
}
EOF

echo "✅ Claude Desktop configuration created"
cat /tmp/claude-desktop-config/claude_desktop_config.json
```{{exec}}

## Test MCP Server Communication

Let's create a simple test to verify our MCP server communication:

```bash
# Create a test client to verify MCP communication
cat > src/test-client.ts << 'EOF'
import { Client } from "@modelcontextprotocol/sdk/client/index.js";
import { StdioClientTransport } from "@modelcontextprotocol/sdk/client/stdio.js";

async function testMCPServer() {
  console.log("Testing MCP server communication...");
  
  try {
    // Create transport to our MCP server
    const transport = new StdioClientTransport({
      command: "node",
      args: ["dist/servers/k8s-mcp-server.js"]
    });

    // Create client
    const client = new Client(
      {
        name: "test-client",
        version: "1.0.0"
      }
    );

    // Connect to the server
    await client.connect(transport);
    console.log("✅ Connected to MCP server");

    // List available resources
    const resources = await client.listResources();
    console.log("📋 Available resources:");
    resources.resources.forEach(resource => {
      console.log(`  - ${resource.name}: ${resource.description}`);
    });

    // List available tools 
    const tools = await client.listTools();
    console.log("🛠️ Available tools:");
    tools.tools.forEach(tool => {
      console.log(`  - ${tool.name}: ${tool.description}`);
    });

    // List available prompts
    const prompts = await client.listPrompts();
    console.log("💬 Available prompts:");
    prompts.prompts.forEach(prompt => {
      console.log(`  - ${prompt.name}: ${prompt.description}`);
    });

    // Test reading a resource
    console.log("\n🔍 Testing cluster-nodes resource:");
    try {
      const clusterNodes = await client.readResource({
        uri: "k8s://cluster/nodes"
      });
      console.log(`  Resource content length: ${clusterNodes.contents[0].text?.length || 0} characters`);
    } catch (error) {
      console.log(`  Resource test failed: ${error.message}`);
    }

    console.log("\n✅ MCP server test completed successfully!");
    
  } catch (error) {
    console.error("❌ MCP server test failed:", error.message);
  }
}

testMCPServer();
EOF

echo "Created MCP client test"
```{{exec}}

## Run the MCP Communication Test

```bash
# Compile and run the test
npm run build
node dist/test-client.js
```{{exec}}

## MCP Integration Patterns

Let's understand different integration patterns:

```bash
echo "=== MCP Integration Patterns ==="
echo ""
echo "1. 📱 Claude Desktop Integration:"
echo "   - Uses stdio transport"
echo "   - Configuration via claude_desktop_config.json"
echo "   - Tools available in Claude chat interface"
echo ""
echo "2. 🖥️ VS Code Integration:"
echo "   - Extension-based integration"
echo "   - Configurable server endpoints"
echo "   - Tools in command palette"
echo ""
echo "3. 🌐 HTTP Integration:"
echo "   - Streamable HTTP transport"
echo "   - RESTful API endpoints"
echo "   - Web-based AI applications"
echo ""
echo "4. 🔧 Custom Integration:"
echo "   - Direct SDK usage"
echo "   - Custom transport implementations"
echo "   - Embedded in applications"
```{{exec}}

## Create HTTP Server Version

Let's also create an HTTP version of our server:

```bash
cat > src/servers/k8s-mcp-http-server.ts << 'EOF'
import express from 'express';
import { McpServer } from "@modelcontextprotocol/sdk/server/mcp.js";
import { StreamableHTTPServerTransport } from "@modelcontextprotocol/sdk/server/streamableHttp.js";
import { randomUUID } from 'crypto';

// Import our existing server configuration
import { server } from './k8s-mcp-server.js';

const app = express();
app.use(express.json());

// Simple session storage
const transports: { [sessionId: string]: StreamableHTTPServerTransport } = {};

// Handle MCP requests
app.post('/mcp', async (req, res) => {
  const sessionId = req.headers['mcp-session-id'] as string | undefined;
  let transport: StreamableHTTPServerTransport;
  
  if (sessionId && transports[sessionId]) {
    transport = transports[sessionId];
  } else {
    transport = new StreamableHTTPServerTransport({
      sessionIdGenerator: () => randomUUID(),
      onsessioninitialized: (id) => {
        transports[id] = transport;
      }
    });
    
    await server.connect(transport);
  }
  
  await transport.handleRequest(req, res, req.body);
});

// Start HTTP server
const PORT = 3001;
app.listen(PORT, () => {
  console.log(`MCP HTTP Server running on port ${PORT}`);
});
EOF

# Add HTTP server dependencies
npm install express
npm install --save-dev @types/express

echo "✅ HTTP MCP server created"
```{{exec}}

## Connection Summary

Your MCP server is now ready for multiple integration patterns:

```bash
echo "🎉 MCP Server Integration Summary:"
echo ""
echo "📋 Server Capabilities:"
echo "  - Resources: cluster-nodes, namespace-pods/{namespace}"
echo "  - Tools: create-pod, get-pod-logs, delete-pod"
echo "  - Prompts: troubleshoot-pod, optimize-resources"
echo ""
echo "🔌 Available Transports:"
echo "  - stdio: dist/servers/k8s-mcp-server.js"
echo "  - HTTP: dist/servers/k8s-mcp-http-server.js (port 3001)"
echo ""
echo "🤖 Ready for AI Integration:"
echo "  - Claude Desktop (stdio)"
echo "  - VS Code Extensions"
echo "  - Custom AI applications"
echo "  - Web-based AI tools"
```{{exec}}

Excellent! Your MCP server is now ready to connect with AI applications. In the next step, we'll dive into Kubernetes controller fundamentals!
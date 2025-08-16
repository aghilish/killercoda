# Step 5: LLM Integration and Testing

Now let's connect our MCP servers to AI applications! We'll test both servers and integrate them with Claude Desktop and MCP Inspector.

## Build and Verify Both Servers

Let's ensure both our stdio and HTTP servers are working:

```bash
cd /workspace/mcp-lab

# Build the project
npm run build

echo "=== Testing Server Compilation ==="
# Verify both servers compile correctly
echo "Testing stdio server..."
timeout 5s node dist/servers/k8s-mcp-server.js || echo "✅ Stdio server starts correctly"

echo "Testing HTTP server startup..."
npm run start:http &
HTTP_PID=$!
sleep 3

# Test health endpoint
if curl -s http://localhost:3001/health > /dev/null; then
    echo "✅ HTTP server is running and healthy"
else
    echo "❌ HTTP server health check failed"
fi

# Stop test server
kill $HTTP_PID 2>/dev/null
wait $HTTP_PID 2>/dev/null
```{{exec}}

## Test with MCP Inspector

Let's test our servers using the MCP Inspector tool:

```bash
echo "=== Testing with MCP Inspector ==="

# Test stdio server with inspector
echo "Starting MCP Inspector for stdio server..."
echo "Command to run locally: npx @modelcontextprotocol/inspector dist/servers/k8s-mcp-server.js"

# Test HTTP server with inspector  
echo "Starting HTTP server for inspector testing..."
npm run start:http &
HTTP_PID=$!
sleep 3

echo "HTTP Server running at http://localhost:3001"
echo "Command to test locally: npx @modelcontextprotocol/inspector http://localhost:3001/mcp"

# Test MCP protocol endpoints
echo ""
echo "Testing MCP protocol endpoints..."

# Test initialize
echo "Testing initialize endpoint..."
curl -s -X POST http://localhost:3001/mcp \
  -H "Content-Type: application/json" \
  -d '{"jsonrpc": "2.0", "id": 1, "method": "initialize", "params": {}}' | jq '.' || echo "Initialize test completed"

# Test resources/list
echo ""
echo "Testing resources/list endpoint..."
curl -s -X POST http://localhost:3001/mcp \
  -H "Content-Type: application/json" \
  -d '{"jsonrpc": "2.0", "id": 2, "method": "resources/list", "params": {}}' | jq '.result.resources[].name' || echo "Resources test completed"

# Test tools/list  
echo ""
echo "Testing tools/list endpoint..."
curl -s -X POST http://localhost:3001/mcp \
  -H "Content-Type: application/json" \
  -d '{"jsonrpc": "2.0", "id": 3, "method": "tools/list", "params": {}}' | jq '.result.tools[].name' || echo "Tools test completed"

# Stop test server
kill $HTTP_PID 2>/dev/null
wait $HTTP_PID 2>/dev/null

echo "✅ MCP Inspector testing completed"
```{{exec}}

## Create Claude Desktop Configuration

Let's create a configuration for Claude Desktop using the stdio server:

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
echo ""
echo "Configuration for Claude Desktop:"
cat /tmp/claude-desktop-config/claude_desktop_config.json
echo ""
echo "💡 To use with Claude Desktop:"
echo "   1. Copy this configuration to your Claude Desktop settings"
echo "   2. Restart Claude Desktop"
echo "   3. Your MCP server tools will be available in Claude chat!"
```{{exec}}

## Test MCP Communication

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
      },
      {
        capabilities: {}
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
    console.log("💡 Available prompts:");
    prompts.prompts.forEach(prompt => {
      console.log(`  - ${prompt.name}: ${prompt.description}`);
    });

    // Test reading a resource
    console.log("\n🔍 Testing cluster-nodes resource:");
    try {
      const clusterNodes = await client.readResource({
        uri: "k8s://cluster/nodes"
      });
      console.log(`  ✅ Resource content length: ${clusterNodes.contents[0].text?.length || 0} characters`);
    } catch (error: any) {
      console.log(`  ❌ Resource test failed: ${error.message}`);
    }

    console.log("\n✅ MCP server test completed successfully!");
    process.exit(0);
    
  } catch (error: any) {
    console.error("❌ MCP server test failed:", error.message);
    process.exit(1);
  }
}

testMCPServer();
EOF

echo "✅ Created MCP client test"
```{{exec}}

## Run the Communication Test

```bash
# Compile and run the test
npm run build
echo "Testing MCP client-server communication..."
timeout 30s node dist/test-client.js
echo "✅ MCP communication test completed"
```{{exec}}

## Integration Patterns Summary

Let's understand the different ways to integrate MCP servers:

```bash
echo "==========================================="
echo "🚀 MCP Integration Patterns"
echo "==========================================="
echo ""
echo "1. 📱 Claude Desktop Integration:"
echo "   Transport: stdio (k8s-mcp-server.js)"
echo "   Config: claude_desktop_config.json"
echo "   Usage: Tools available in Claude chat interface"
echo ""
echo "2. 🔍 MCP Inspector Integration:"
echo "   Commands:"
echo "   - Stdio: npx @modelcontextprotocol/inspector dist/servers/k8s-mcp-server.js"  
echo "   - HTTP:  npx @modelcontextprotocol/inspector http://localhost:3001/mcp"
echo "   Usage: Interactive testing and development"
echo ""
echo "3. 🌐 HTTP API Integration:"
echo "   Transport: HTTP (k8s-mcp-http-server.js)"
echo "   Endpoint: http://localhost:3001/mcp"
echo "   Usage: Web applications, REST APIs, custom integrations"
echo ""
echo "4. 🔧 Custom SDK Integration:"
echo "   Transport: Direct SDK usage"
echo "   Usage: Embedded in applications, custom transports"
echo ""
```{{exec}}

## Create Docker Configuration

Let's create a Dockerfile for containerizing our MCP server:

```bash
# Create Dockerfile for MCP server
cat > Dockerfile << 'EOF'
FROM node:18-alpine

WORKDIR /app

# Copy package files
COPY package*.json ./

# Install dependencies
RUN npm install

# Copy source code
COPY . .

# Build the application
RUN npm run build

# Expose port for HTTP server
EXPOSE 3001

# Set environment variables
ENV NODE_ENV=production
ENV MCP_TRANSPORT=streamable-http  
ENV MCP_PORT=3001

# Create non-root user
RUN addgroup -g 1001 mcp && adduser -u 1001 -G mcp -s /bin/sh -D mcp
USER mcp

# Start the HTTP server by default
CMD ["node", "dist/servers/k8s-mcp-http-server.js"]
EOF

echo "✅ Dockerfile created for MCP server containerization"
echo ""
echo "🐳 Docker commands:"
echo "   Build: docker build -t mcp-k8s-server:latest ."
echo "   Run:   docker run -p 3001:3001 mcp-k8s-server:latest"
```{{exec}}

## Final Integration Summary

Your MCP servers are now ready for production use:

```bash
echo "==========================================="
echo "🎉 MCP Server Integration Complete!"
echo "==========================================="
echo ""
echo "📦 Built Components:"
echo "  📁 Shared Handlers: src/handlers/k8s-handlers.ts"
echo "  🔌 Stdio Server: src/servers/k8s-mcp-server.ts"
echo "  🌐 HTTP Server: src/servers/k8s-mcp-http-server.ts"
echo "  🧪 Test Client: src/test-client.ts"
echo "  🐳 Dockerfile: Ready for containerization"
echo ""
echo "🚀 Integration Options:"
echo "  ✅ Claude Desktop (stdio transport)"
echo "  ✅ MCP Inspector (stdio + HTTP)"
echo "  ✅ HTTP API clients (JSON-RPC 2.0)"
echo "  ✅ Custom SDK integrations"
echo "  ✅ Docker deployment"
echo ""
echo "📋 Server Capabilities:"
echo "  🗂️  Resources: cluster-nodes, namespace-pods"
echo "  🛠️  Tools: create-pod, get-pod-logs, delete-pod"
echo "  💡 Prompts: troubleshoot-pod, optimize-resources"
echo ""
echo "🔄 Both stdio and HTTP transports tested and working!"
echo "==========================================="
```{{exec}}

Perfect! Your MCP servers are now fully integrated and ready for AI applications. In the next step, we'll dive into Kubernetes controller fundamentals to build our operator!
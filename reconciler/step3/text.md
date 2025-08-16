# Step 3: MCP Development Environment Setup

Let's set up everything we need to build production-ready MCP servers and connect them to AI applications like Claude Desktop.

## Verify Prerequisites

First, let's verify we have the required tools:

```bash
# Check Node.js version (should be 18+)
node --version

# Check npm version
npm --version

# Verify Kubernetes cluster access
kubectl cluster-info
kubectl get nodes
```{{exec}}

## Create MCP Lab Project

Set up our MCP development workspace with the proven working configuration:

```bash
# Create workspace
mkdir -p /workspace/mcp-lab
cd /workspace/mcp-lab

# Initialize project
npm init -y
```{{exec}}

## Install Proven Dependencies

Install the exact versions that we've tested and verified to work:

```bash
# Install core MCP and Kubernetes dependencies
npm install @modelcontextprotocol/sdk@1.17.3 zod@3.25.76 @kubernetes/client-node@1.3.0

# Install HTTP server dependencies
npm install express@4.18.2 js-yaml@4.1.0

# Install development dependencies
npm install --save-dev typescript@5.9.2 @types/node@24.3.0 ts-node@10.9.2 tsx@4.20.4
npm install --save-dev @types/express@5.0.3 @types/js-yaml@4.0.9

echo "✅ Dependencies installed successfully"
```{{exec}}

## Create Working Package Configuration

Set up package.json with all the scripts we'll need:

```bash
cat > package.json << 'EOF'
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

echo "✅ Package configuration created"
```{{exec}}

## Setup TypeScript Configuration

Create the TypeScript configuration that works with our MCP servers:

```bash
cat > tsconfig.json << 'EOF'
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
    "rootDir": "./src",
    "declaration": true,
    "declarationMap": true,
    "sourceMap": true
  },
  "include": ["src/**/*"],
  "exclude": ["node_modules", "dist"]
}
EOF

echo "✅ TypeScript configuration created"
```{{exec}}

## Create Project Structure

Set up the directory structure for our MCP servers:

```bash
# Create organized directory structure
mkdir -p src/{servers,handlers,types,utils}
mkdir -p examples config

# Create the handlers directory for shared MCP logic
echo "✅ Created src/handlers/ for shared MCP server logic"
echo "✅ Created src/servers/ for stdio and HTTP server implementations"
echo "✅ Created src/types/ for TypeScript type definitions"
echo "✅ Created src/utils/ for utility functions"
```{{exec}}

## Install Dependencies and Verify Setup

```bash
# Install all dependencies
npm install

# Verify critical dependencies
echo "=== Dependency Verification ==="
npm list @modelcontextprotocol/sdk
npm list @kubernetes/client-node
npm list typescript

echo ""
echo "=== Environment Verification ==="
echo "Node.js: $(node --version)"
echo "npm: $(npm --version)"
echo "TypeScript: $(npx tsc --version)"
```{{exec}}

## Test Kubernetes Connectivity

Verify we can connect to the Kubernetes cluster for our MCP servers:

```bash
# Test basic Kubernetes API access
echo "=== Kubernetes Connectivity Test ==="
kubectl cluster-info

# Check if we can list basic resources
kubectl get namespaces
kubectl get pods --all-namespaces | head -5

# Verify permissions for MCP server operations
echo ""
echo "=== Permission Check ==="
kubectl auth can-i get pods
kubectl auth can-i list nodes
kubectl auth can-i create pods

echo "✅ Kubernetes connectivity verified"
```{{exec}}

## Environment Summary

Let's confirm everything is ready:

```bash
echo "=========================================="
echo "🚀 MCP Development Environment Ready!"
echo "=========================================="
echo "📦 Project: mcp-kubernetes-lab"
echo "🟢 Node.js: $(node --version)"
echo "🟢 TypeScript: $(npx tsc --version)"
echo "🟢 MCP SDK: $(npm list @modelcontextprotocol/sdk --depth=0 | grep @modelcontextprotocol)"
echo "🟢 Kubernetes: Connected"
echo "📁 Structure: src/{servers,handlers,types,utils}"
echo ""
echo "Next: Build your first Kubernetes-aware MCP server!"
echo "=========================================="
```{{exec}}

Perfect! Our development environment is now set up with the exact configuration that we've tested and proven to work. In the next step, we'll build our first MCP server with reusable handlers and both stdio and HTTP transport support.
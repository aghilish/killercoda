# Step 3: Setting up MCP Development Environment

Let's set up everything we need to build MCP servers and connect them to AI applications.

## Install Node.js and npm

First, ensure we have Node.js 18+ for MCP SDK compatibility:

````bash
# Check current Node.js version
node --version

# Install Node.js if needed (using apt on this system)
curl -fsSL https://deb.nodesource.com/setup_20.x | sudo -E bash -
sudo apt-get install -y nodejs

# Verify installation
node --version
npm --version
```{{exec}}

## Install MCP SDK and Dependencies

Now let's install the MCP TypeScript SDK and essential dependencies:

```bash
# Create our MCP workspace
mkdir -p /workspace/mcp-lab
cd /workspace/mcp-lab

# Initialize our project
npm init -y

# Install MCP SDK and dependencies
npm install @modelcontextprotocol/sdk zod

# Install development dependencies
npm install --save-dev typescript @types/node ts-node

# Verify installation
npm list @modelcontextprotocol/sdk
```{{exec}}

## Set up TypeScript Configuration

Create a proper TypeScript configuration:

```bash
# Create tsconfig.json
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
    "rootDir": "./src"
  },
  "include": ["src/**/*"],
  "exclude": ["node_modules", "dist"]
}
EOF

echo "TypeScript configuration created"
```{{exec}}

## Install Kubernetes Client Library

Since we'll be building Kubernetes-aware MCP servers, let's install the Kubernetes JavaScript client:

```bash
# Install Kubernetes client
npm install @kubernetes/client-node

# Install additional utilities
npm install js-yaml

echo "Kubernetes client installed"
```{{exec}}

## Install MCP Inspector for Testing

The MCP Inspector is crucial for testing our MCP servers:

```bash
# Install MCP Inspector globally
npm install -g @modelcontextprotocol/inspector

# Verify installation
mcp-inspector --version || echo "MCP Inspector installed successfully"
```{{exec}}

## Create Project Structure

Let's set up a clean project structure:

```bash
# Create directories
mkdir -p src/{servers,types,utils}
mkdir -p examples
mkdir -p config

# Create package.json scripts
cat > package.json << 'EOF'
{
  "name": "mcp-kubernetes-lab",
  "version": "1.0.0",
  "type": "module",
  "description": "MCP servers for Kubernetes management",
  "main": "dist/index.js",
  "scripts": {
    "build": "tsc",
    "dev": "ts-node --esm src/index.ts",
    "start": "node dist/index.js",
    "inspect": "mcp-inspector src/servers/simple-server.ts"
  },
  "dependencies": {
    "@kubernetes/client-node": "^0.20.0",
    "@modelcontextprotocol/sdk": "^1.0.0",
    "js-yaml": "^4.1.0",
    "zod": "^3.22.0"
  },
  "devDependencies": {
    "@types/node": "^20.0.0",
    "ts-node": "^10.9.0",
    "typescript": "^5.0.0"
  }
}
EOF

echo "Project structure created"
```{{exec}}

## Verify Kubernetes Access

Let's make sure we can connect to the Kubernetes cluster:

```bash
# Check kubectl connectivity
kubectl cluster-info

# Test Kubernetes API access
kubectl get nodes

# Check permissions
kubectl auth can-i get pods
kubectl auth can-i create pods
```{{exec}}

## Create Basic Types

Set up TypeScript types we'll use throughout the lab:

```bash
cat > src/types/index.ts << 'EOF'
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

echo "Basic types created"
```{{exec}}

## Environment Verification

Let's verify our complete setup:

```bash
echo "=== MCP Development Environment Setup Complete ==="
echo "Node.js version: $(node --version)"
echo "npm version: $(npm --version)"
echo "TypeScript: $(npx tsc --version)"
echo "Kubernetes cluster: $(kubectl cluster-info --short)"
echo "Project structure:"
find . -name "*.json" -o -name "*.ts" | head -10
```{{exec}}

Excellent! Our development environment is ready. In the next step, we'll build our first MCP server with Kubernetes integration.

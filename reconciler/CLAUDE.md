# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Overview

This is a comprehensive Killercoda interactive tutorial repository that teaches users how to build a production-ready Kubernetes operator for managing Model Context Protocol (MCP) servers. The tutorial bridges AI tooling with cloud-native infrastructure, combining three essential areas:

1. **MCP Fundamentals** - Understanding Model Context Protocol architecture and building MCP servers
2. **Kubernetes Reconciliation** - Deep-diving into controller patterns and reconciliation loops  
3. **MCP Server Operator** - Building a complete Kubernetes operator for MCP server lifecycle management

## Repository Structure

The repository is structured as a Killercoda scenario with 12 sequential steps:

- `index.json` - Killercoda scenario configuration (12-step tutorial)
- `intro.md` - Tutorial introduction covering all three parts
- `step[1-12]/text.md` - Step-by-step tutorial content
- `step[1-12]/verify.sh` - Verification scripts
- `finish.md` - Tutorial conclusion
- `guide.md` - Comprehensive MCP Server Operator guide (reference)
- `reconciler.md` - Deep dive into Kubernetes controller patterns (reference)
- `mcp-sdk.md` - MCP SDK documentation (reference)
- `llms-full.txt` - Additional MCP documentation (reference)

## Tutorial Flow

### Part 1: MCP Fundamentals (Steps 1-5)
1. **Introduction to MCP** - Protocol overview, architecture, core concepts
2. **MCP Building Blocks** - Resources, tools, prompts, and communication patterns
3. **Development Environment** - Node.js, TypeScript, MCP SDK, Kubernetes client setup
4. **First MCP Server** - Building a Kubernetes-aware MCP server with tools and resources
5. **LLM Integration** - Connecting MCP servers to AI applications like Claude Desktop

### Part 2: Kubernetes Reconciliation (Steps 6-8)
6. **Controller Fundamentals** - Reconciliation loops, level-based reconciliation, control theory
7. **MCPServer CRD** - Defining Custom Resource Definition for MCP server management
8. **Reconciliation Patterns** - Finalizers, status management, error handling, retry strategies

### Part 3: MCP Server Operator (Steps 9-12)
9. **Operator Architecture** - Planning MCPServer operator structure and components
10. **Controller Implementation** - Core reconciliation logic, RBAC, event handling
11. **Deployment Management** - Pod/service creation, configuration management, networking
12. **Production Considerations** - Security, monitoring, testing, scaling strategies

## Key Commands and Technologies

### MCP Development Stack
```bash
# Node.js and MCP SDK setup
npm install @modelcontextprotocol/sdk zod @kubernetes/client-node
npm install -g @modelcontextprotocol/inspector

# MCP server development
npm run build
npm run dev
mcp-inspector src/servers/server.ts
```

### Kubernetes Operator Development
```bash
# Kubebuilder workflow (for operator implementation)
kubebuilder init --domain mcp.example.com --repo github.com/example/mcp-operator
kubebuilder create api --group mcp --version v1alpha1 --kind MCPServer --controller --resource

# Standard operator commands
make generate
make manifests
make install
make run
make docker-build
```

### Testing and Verification
```bash
# Kubernetes cluster operations
kubectl get mcpservers
kubectl describe mcpserver example-mcp
kubectl logs -f deployment/mcp-operator-controller-manager

# MCP server testing
curl -X POST http://mcp-server:8080/mcp -H "Content-Type: application/json"
```

## Technical Focus Areas

### Model Context Protocol (MCP)
- **Architecture**: Client-server protocol using JSON-RPC 2.0
- **Transports**: stdio, HTTP/SSE (legacy), Streamable HTTP (modern)
- **Core Primitives**: Resources (data), Tools (actions), Prompts (templates)
- **Integration**: Connection patterns with LLMs (Claude, ChatGPT, VS Code)

### Kubernetes Operator Patterns
- **MCPServer CRD**: Custom resource for MCP server specification
- **Controller Logic**: Reconciliation loops, status reporting, event handling
- **Resource Management**: Pod/Service creation, ConfigMap/Secret handling
- **Operational Concerns**: Finalizers, RBAC, monitoring, scaling

### Production Considerations
- **Security**: RBAC policies, network policies, secret management
- **Reliability**: Health checks, restarts, resource limits
- **Observability**: Metrics, logging, tracing, alerting
- **Scalability**: Horizontal pod autoscaling, resource optimization

## Real-World Examples Referenced

The tutorial draws inspiration from production MCP server operators:
- **containers/kubernetes-mcp-server** - Native Go implementation with direct API access
- **Azure/mcp-kubernetes** - Enterprise-grade MCP server with configurable access levels
- **Flux159/mcp-server-kubernetes** - kubectl-based MCP server with safety features
- **ToolHive Operator** - Kubernetes operator for secure MCP server deployment

## Architecture Patterns

### MCP Server Deployment Architecture
```
AI Application (Claude/ChatGPT) 
    ↓ MCP Protocol
MCP Client 
    ↓ HTTP/stdio
Kubernetes Service
    ↓ 
MCPServer Pod (deployed by operator)
    ↓ Kubernetes API
Cluster Resources
```

### Operator Control Loop
```
MCPServer CR → Controller → Deployment/Service → Pod → MCP Server → Status Update
```

## Development Workflow

1. **MCP Server Development**: Build and test MCP servers locally using TypeScript/Node.js
2. **CRD Design**: Define MCPServer custom resource specification
3. **Controller Implementation**: Implement reconciliation logic using Kubebuilder
4. **Integration Testing**: Deploy operator and test with real MCP clients
5. **Production Deployment**: RBAC, security hardening, monitoring setup

This tutorial provides a complete end-to-end experience of building AI-native infrastructure components for Kubernetes, making MCP servers first-class citizens in cloud-native environments.
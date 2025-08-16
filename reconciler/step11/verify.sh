#!/bin/bash

# Verify that the MCPServer CRD is installed
if ! kubectl get crd mcpservers.mcp.example.com >/dev/null 2>&1; then
    echo "MCPServer CRD not installed"
    exit 1
fi

# Check if sample resources exist
if [ ! -f "/workspace/mcp-operator/config/samples/mcp_v1alpha1_mcpserver_basic.yaml" ]; then
    echo "Basic MCPServer sample not found"
    exit 1
fi

if [ ! -f "/workspace/mcp-operator/config/samples/mcp_v1alpha1_mcpserver_advanced.yaml" ]; then
    echo "Advanced MCPServer sample not found"
    exit 1
fi

# Check if operator binary was built
if [ ! -f "/workspace/mcp-operator/bin/manager" ]; then
    echo "MCPServer operator binary not found - run 'make build' first"
    exit 1
fi

echo "✅ MCPServer operator testing and production setup verified"
exit 0
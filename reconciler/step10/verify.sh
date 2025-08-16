#!/bin/bash

# Verify that the MCPServer operator project structure exists
if [ ! -d "/workspace/mcp-operator" ]; then
    echo "MCPServer operator project directory not found"
    exit 1
fi

# Check if basic project files exist
if [ ! -f "/workspace/mcp-operator/Makefile" ]; then
    echo "MCPServer operator Makefile not found"
    exit 1
fi

# Check if the MCPServer types are defined
if [ ! -f "/workspace/mcp-operator/api/v1alpha1/mcpserver_types.go" ]; then
    echo "MCPServer types not found"
    exit 1
fi

# Check if controller files exist
if [ ! -f "/workspace/mcp-operator/controllers/mcpserver_controller.go" ]; then
    echo "MCPServer controller not found"
    exit 1
fi

echo "✅ MCPServer operator deployment management components verified"
exit 0
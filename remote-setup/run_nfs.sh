#!/bin/bash

# Trap Ctrl+C (SIGINT) and SIGTERM to trigger cleanup
cleanup() {
    echo ""
    echo "Stopping NFS server..."
    docker compose -f compose.nfs.yaml down
    exit 0
}

trap cleanup SIGINT SIGTERM EXIT

echo "==============================================="
echo "Starting NFS server..."
echo "Press Ctrl+C to stop and clean up"
echo "Or use docker compose -f compose.nfs.yaml down to stop the server manually."
echo "==============================================="

# Run with --abort-on-container-exit to stop if container crashes
docker compose -f compose.nfs.yaml up --abort-on-container-exit
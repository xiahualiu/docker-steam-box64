#!/bin/bash
# Example script to run a Valheim server

set -e

# Create necessary directories
mkdir -p valheim-data valheim-config

# Build the image
echo "Building Docker image..."
docker compose build

# Start the Valheim server
echo "Starting Valheim server..."
docker compose --profile valheim up -d valheim

echo ""
echo "Valheim server is starting!"
echo "View logs with: docker compose logs -f valheim"
echo "Stop server with: docker compose --profile valheim down"
echo ""
echo "Note: Edit docker-compose.yml to configure server name, password, etc."

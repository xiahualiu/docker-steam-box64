#!/bin/bash
# Example script to run a Palworld server

set -e

# Create necessary directories
mkdir -p palworld-data palworld-config

# Build the image
echo "Building Docker image..."
docker compose build

# Start the Palworld server
echo "Starting Palworld server..."
docker compose --profile palworld up -d palworld

echo ""
echo "Palworld server is starting!"
echo "View logs with: docker compose logs -f palworld"
echo "Stop server with: docker compose --profile palworld down"
echo ""
echo "Note: Edit docker-compose.yml to configure server name, password, etc."

#!/bin/bash
# Palworld server startup script with safe parameter handling
set -e

# Set defaults if not provided
SERVER_NAME="${SERVER_NAME:-My Palworld Server}"
SERVER_DESC="${SERVER_DESC:-A Palworld Dedicated Server}"
SERVER_PASSWORD="${SERVER_PASSWORD:-secret}"
ADMIN_PASSWORD="${ADMIN_PASSWORD:-adminpass}"
MAX_PLAYERS="${MAX_PLAYERS:-32}"
SERVER_PORT="${SERVER_PORT:-8211}"
PUBLIC_PORT="${PUBLIC_PORT:-8211}"

echo "Starting Palworld server setup..."
echo "Server Name: $SERVER_NAME"
echo "Max Players: $MAX_PLAYERS"
echo "Server Port: $SERVER_PORT"

# Install/update the server
"${STEAMCMDDIR}/steamcmd.sh" \
    +force_install_dir /home/steam/palworld-server \
    +login anonymous \
    +app_update 2394010 validate \
    +quit

echo "Server files ready. Starting Palworld server..."

# Run the server
cd /home/steam/palworld-server
exec box64 ./PalServer.sh

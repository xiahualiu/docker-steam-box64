#!/bin/bash
# Valheim server startup script with safe parameter handling
set -e

# Set defaults if not provided
SERVER_NAME="${SERVER_NAME:-My Valheim Server}"
WORLD_NAME="${WORLD_NAME:-Dedicated}"
SERVER_PASS="${SERVER_PASS:-secret}"
SERVER_PUBLIC="${SERVER_PUBLIC:-0}"

echo "Starting Valheim server setup..."
echo "Server Name: $SERVER_NAME"
echo "World Name: $WORLD_NAME"
echo "Public: $SERVER_PUBLIC"

# Install/update the server
"${STEAMCMDDIR}/steamcmd.sh" \
    +force_install_dir /home/steam/valheim-server \
    +login anonymous \
    +app_update 896660 validate \
    +quit

echo "Server files ready. Starting Valheim server..."

# Run the server with properly escaped arguments
cd /home/steam/valheim-server
exec box64 ./valheim_server.x86_64 \
    -name "$SERVER_NAME" \
    -port 2456 \
    -world "$WORLD_NAME" \
    -password "$SERVER_PASS" \
    -public "$SERVER_PUBLIC"

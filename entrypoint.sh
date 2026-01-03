#!/bin/bash
set -e

echo "Checking for Box64 updates..."
cd "${BOX64_DIR}" || exit 1

# Store current commit hash
CURRENT_COMMIT=$(git rev-parse HEAD)

# Fetch latest changes
git fetch origin
LATEST_COMMIT=$(git rev-parse origin/main)

# Check if update is needed
if [ "$CURRENT_COMMIT" != "$LATEST_COMMIT" ]; then
    echo "New Box64 version available. Updating..."
    git pull origin main
    cd build
    cmake .. -DARM_DYNAREC=ON -DCMAKE_BUILD_TYPE=RelWithDebInfo
    make -j$(nproc)
    make install
    ldconfig
    echo "Box64 updated successfully!"
else
    echo "Box64 is already up to date."
fi

# Switch to steam user and execute the command
if [ "$#" -eq 0 ]; then
    exec su - steam
else
    exec su - steam -c "$@"
fi

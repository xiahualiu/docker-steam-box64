#!/bin/bash
set -e
set -o pipefail

echo "=================================================="
echo "Docker Steam Box64 - ARM64 Game Server Container"
echo "=================================================="
echo "NOTE: This container uses:"
echo "- Box64 for game servers (x86-64)"
echo "- Box32 for SteamCMD (x86)"
echo "=================================================="

log() {
    echo "$@"
}

warn() {
    echo "WARNING: $@"
}

error() {
    echo "ERROR: $@"
}

require_writable_dir() {
    # Usage: require_writable_dir_or_exit ENV_NAME
    local env_name="$1"
    local dir_path="${!env_name}"

    if [ ! -d "${dir_path}" ]; then
        warn "${env_name} is not set or does not exist. Files may not persist."
        exit 2
    fi

    if [ ! -w "${dir_path}" ]; then
        error "${env_name}=${dir_path} is not writable by the current user ${USER}."
        error "It is owned by UID:GID $(stat -c '%u:%g' "${dir_path}")."
        error "Current user is UID:GID $(id -u):$(id -g)."
        exit 1
    fi
}

install_or_update_steamcmd() {
    if [ -f "${STEAMCMD_DIR}/steamcmd.sh" ]; then
        log "SteamCMD already installed in: ${STEAMCMD_DIR}"
        return 0
    fi

    log "Installing SteamCMD to: ${STEAMCMD_DIR}"
    pushd "${STEAMCMD_DIR}" >/dev/null

    curl -L --fail https://steamcdn-a.akamaihd.net/client/installer/steamcmd_linux.tar.gz | tar zxvf -

    local attempt=0
    local max=4
    while true; do
        local rc=0
        box64 ./linux32/steamcmd +login anonymous +quit 2>&1 || rc=$?

        if [ "${rc}" -eq 0 ]; then
            break
        fi

        if [ "${rc}" -eq 42 ]; then
            attempt=$((attempt + 1))
            if [ "${attempt}" -ge "${max}" ]; then
                log "SteamCMD exited 42 after ${attempt} attempts, continuing"
                break
            fi
            log "SteamCMD exited 42, retrying (${attempt}/${max})..."
            sleep 1
            continue
        fi

        error "SteamCMD update failed with code ${rc}"
        exit "${rc}"
    done

    # Create Steam SDK symlinks used by many servers/games (64-bit and 32-bit)
    mkdir -p ${HOME}/.steam/sdk64 ${HOME}/.steam/sdk32
    ln -sf ${STEAMCMD_DIR}/linux64/steamclient.so ${HOME}/.steam/sdk64/steamclient.so
    ln -sf ${STEAMCMD_DIR}/linux32/steamclient.so ${HOME}/.steam/sdk32/steamclient.so
    ln -sf ${STEAMCMD_DIR}/linux64/steamclient.so ${HOME}/.steam/sdk64/steamservice.so
    ln -sf ${STEAMCMD_DIR}/linux32/steamclient.so ${HOME}/.steam/sdk32/steamservice.so
    ln -sf ${STEAMCMD_DIR}/linux64 ${HOME}/.steam/bin64
    ln -sf ${STEAMCMD_DIR}/linux32 ${HOME}/.steam/bin32

    popd >/dev/null
    log "Initialization complete. Starting game server..."
}

update_game_server() {
    log "Updating game server via SteamCMD (AppID: ${GAME_APP_ID})..."
    pushd "${STEAMCMD_DIR}" >/dev/null
    box64 ./linux32/steamcmd +force_install_dir "${GAME_SERVER_DIR}" +login anonymous +app_update "${GAME_APP_ID}" validate +quit
    popd >/dev/null
    log "Game server update complete."
}

run_game_server() {
    # Run the game via box64
    if [ -z "${GAME_EXECUTABLE}" ] || [ ! -f "${GAME_SERVER_DIR}/${GAME_EXECUTABLE}" ]; then
        error "GAME_EXECUTABLE is not set or does not exist: ${GAME_SERVER_DIR}/${GAME_EXECUTABLE}"
        error "Set GAME_EXECUTABLE so that GAME_SERVER_DIR/GAME_EXECUTABLE points to the game server executable."
        exit 1
    fi
    # Valheim need SteamID and LD_LIBRARY_PATH to steamclient.so
    export SteamAppId=892970
    export LD_LIBRARY_PATH=${STEAMCMD_DIR}/linux64:$LD_LIBRARY_PATH

    box64 "${GAME_SERVER_DIR}/${GAME_EXECUTABLE}" \
    -nographics \
    -batchmode \
    -name "蛋炒饭赛博羊毛服务器" \
    -savedir "${GAME_SAVE_DIR}" \
    -world "MINISHIJIE" \
    -password "12344321" \
    -port "2456" \
    -public 1
}

# Ensure required directories exist and have correct permissions
require_writable_dir "GAME_SERVER_DIR"
require_writable_dir "GAME_SAVE_DIR"
require_writable_dir "STEAMCMD_DIR"

install_or_update_steamcmd
update_game_server
run_game_server

# Execute the requested command (container runs as UID/GID 1001 in compose)
if [ "$#" -eq 0 ]; then
    exec /bin/bash
else
    exec "$@"
fi
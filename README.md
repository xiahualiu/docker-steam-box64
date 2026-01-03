# docker-steam-box64

Ubuntu 24.04 image for ARM64 that bundles Box64 + SteamCMD so you can run many x86-64 Linux dedicated game servers on AArch64 hosts.

## Requirements

- Docker + Docker Compose
- ARM64 host (Box64 runs on AArch64)
- Host paths for server/save/steamcmd that are writable by the container user

## Quick start

1) Edit the defaults in `docker-compose.yml` (recommended):

- Set `build.args.USER_UID` and `user` to your host UID (check with `id -u`).
- Change the three bind mounts under `volumes:` to directories you want to persist.

2) Create mount point directories on the host.

```bash
mkdir -p /mnt/data/server /mnt/data/save /mnt/data/steamcmd
```

3) Build + run:

```bash
docker compose build
docker compose up -d
```

## Install/update a Steam game server

SteamCMD is installed on first start into `$STEAMCMD_DIR` (see `docker-compose.yml`). To install/update a server:

```bash
cd "$STEAMCMD_DIR"
box64 ./linux32/steamcmd \
	+force_install_dir "$GAME_SERVER_DIR" \
	+login anonymous \
	+app_update <APP_ID> validate \
	+quit
```

Then run your server (example):

```bash
cd "$GAME_SERVER_DIR"
box64 ./server_executable
```

## Notes

- The entrypoint requires `GAME_SERVER_DIR`, `GAME_SAVE_DIR`, and `STEAMCMD_DIR` to exist and be writable (it exits otherwise).
- Box64 is built into the image at build time (it is not auto-updated on container start).

## Troubleshooting

```bash
# Box64 version
docker compose run steam-box64 box64 -v

# Rebuild image from scratch
docker compose build --no-cache
```

## License

See [LICENSE](LICENSE).

## Credits

- Box64: https://github.com/ptitSeb/box64
- SteamCMD: https://developer.valvesoftware.com/wiki/SteamCMD

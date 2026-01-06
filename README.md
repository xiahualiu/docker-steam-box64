# docker-steam-box64

Ubuntu 24.04 ARM64 image bundling Box64 + SteamCMD to run many x86-64 Linux dedicated servers on AArch64 hosts.

## Requirements

- Docker + Docker Compose
- ARM64 host (Box64 runs on AArch64)

## Quick start

### 1) Configure `docker-compose.yml`

- Set `USER_UID` to your host UID (`id -u`) so created files map to your user.
- Update the bind mount paths for your server files/saves/SteamCMD to match your host.

### 2) Create host directories

Create the bind mount directories on the host first; otherwise Docker may create them as root and the container user may not be able to write to them.

```bash
mkdir -p server valheim-save steamcmd
```

### 3) Build + run

```bash
docker compose up
```

Rebuild the image:

```bash
docker compose build
```

## License

See [LICENSE](LICENSE).

## Credits

- Box64: https://github.com/ptitSeb/box64
- SteamCMD: https://developer.valvesoftware.com/wiki/SteamCMD

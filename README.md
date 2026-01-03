# docker-steam-box64

Docker container with SteamCMD and Box64 emulator for running x86-64 game servers on ARM64 architecture (like Oracle Cloud Ampere A1).

## Features

- **Base OS**: Ubuntu 24.04
- **SteamCMD**: Pre-installed and ready to download game servers
- **Box64**: ARM64 emulator for x86-64 applications with auto-update on container start
- **Optimized**: Configured for optimal performance on ARM64 hardware
- **Examples**: Includes docker-compose configurations for Valheim and Palworld

## Prerequisites

- Docker and Docker Compose installed
- ARM64 architecture (e.g., Oracle Cloud Ampere A1, Raspberry Pi 4/5, Apple Silicon)
- Sufficient storage for game servers (10-20GB recommended)

## Quick Start

### 1. Clone the repository

```bash
git clone https://github.com/xiahualiu/docker-steam-box64.git
cd docker-steam-box64
```

### 2. Configure User Permissions (Optional but Recommended)

To ensure proper file permissions on mounted volumes, configure the user UID/GID:

```bash
# Create .env file from example
cp .env.example .env

# Find your user's UID and GID
id

# Edit .env and set PUID and PGID to match your user
# For example, if id shows uid=1001 gid=1001:
# PUID=1001
# PGID=1001
```

This ensures files created by the container will be owned by your user on the host system.

### 3. Build the image

```bash
docker compose build
```

**Note:** If you've previously built the image and change PUID/PGID values, you need to rebuild:
```bash
docker compose build --no-cache
```

### 4. Run a game server

#### Generic usage (interactive shell)

```bash
docker compose up -d
docker compose exec steam-box64 bash
```

Inside the container, you can use SteamCMD:
```bash
cd ~/steamcmd
./steamcmd.sh +login anonymous +app_update <APP_ID> +quit
```

#### Run Valheim server

1. Edit environment variables in `docker-compose.yml` (server name, password, etc.)
2. Uncomment the `command` section for the Valheim service
3. Start the server:

```bash
docker compose --profile valheim up -d valheim
```

View logs:
```bash
docker compose logs -f valheim
```

#### Run Palworld server

1. Edit environment variables in `docker-compose.yml`
2. Uncomment the `command` section for the Palworld service
3. Start the server:

```bash
docker compose --profile palworld up -d palworld
```

View logs:
```bash
docker compose logs -f palworld
```

## Architecture

- **Dockerfile**: Builds the base image with Ubuntu 24.04, SteamCMD, and Box64
- **docker-compose.yml**: Provides service configurations for different game servers
- **Entrypoint**: Automatically updates Box64 on container start

### Box64 Auto-Update

Every time the container starts, it checks for Box64 updates from the official repository and rebuilds if a new version is available. This ensures you always have the latest compatibility and performance improvements.

## Supported Game Servers

This container can run most x86-64 Linux dedicated game servers on ARM64, including:

- **Valheim** (App ID: 896660)
- **Palworld** (App ID: 2394010)
- **7 Days to Die** (App ID: 294420)
- **ARK: Survival Evolved** (App ID: 376030)
- **Rust** (App ID: 258550)
- **CS:GO** (App ID: 740)
- **Team Fortress 2** (App ID: 232250)
- And many more...

## Volume Mounts

The docker-compose.yml includes volume mounts for:

- **Game data**: Persists game server files
- **Config files**: Persists configuration
- **SteamCMD**: Persists downloaded files to avoid re-downloading

### File Permissions

To ensure proper file permissions on mounted volumes, you can set custom UID and GID for the steam user:

1. Create a `.env` file in the project root (copy from `.env.example`):
```bash
cp .env.example .env
```

2. Find your user's UID and GID on the host system:
```bash
id
```

3. Edit `.env` and set PUID and PGID to match your host user:
```env
PUID=1000
PGID=1000
```

4. Build the image with these values:
```bash
docker compose build
```

This ensures that files created by the container on mounted volumes will have the correct ownership on your host system, making them easy to manage, backup, and modify.

## Ports

Default exposed ports (can be customized in docker-compose.yml):

- **27015-27020**: Common game server ports (TCP/UDP)
- **Valheim**: 2456-2458 (UDP)
- **Palworld**: 8211, 27015 (UDP)

## Environment Variables

### User Configuration (Build Arguments)

These are set in the `.env` file and used during image build:

- `PUID=1000`: User ID for the steam user inside the container
- `PGID=1000`: Group ID for the steam user inside the container

### Box64 Configuration (already set in Dockerfile)

- `BOX64_NOBANNER=1`: Suppresses Box64 startup banner
- `BOX64_LOG=0`: Disables verbose logging
- `BOX64_DYNAREC_BIGBLOCK=1`: Enables big block optimization
- `BOX64_DYNAREC_STRONGMEM=1`: Enables strong memory model

### SteamCMD

- `STEAMCMDDIR=/home/steam/steamcmd`: SteamCMD installation directory

## Custom Game Server Setup

To run a different game server:

1. Create a new service in `docker-compose.yml` based on the examples
2. Find the Steam App ID from [SteamDB](https://steamdb.info/)
3. Configure the appropriate ports
4. Set up the startup command using SteamCMD and Box64

Example command structure:
```bash
# Download/update the server
${STEAMCMDDIR}/steamcmd.sh +force_install_dir /home/steam/gameserver +login anonymous +app_update <APP_ID> validate +quit

# Run the server with Box64
cd /home/steam/gameserver
box64 ./server_executable
```

## Troubleshooting

### Check Box64 version
```bash
docker compose exec steam-box64 box64 -v
```

### Check if a binary is x86-64
```bash
docker compose exec steam-box64 file /path/to/binary
```

### View container logs
```bash
docker compose logs -f
```

### Interactive shell access
```bash
docker compose exec steam-box64 bash
```

### Force Box64 rebuild
```bash
docker compose down
docker compose build --no-cache
docker compose up -d
```

## Performance Notes

- ARM64 CPUs (like Ampere A1) provide good performance for most game servers
- Box64 overhead is typically 10-30% depending on the game
- Ensure sufficient RAM (4GB+ recommended for most servers)
- Use SSD storage for better I/O performance

## Contributing

Contributions are welcome! Please feel free to submit issues or pull requests.

## License

See [LICENSE](LICENSE) file for details.

## Acknowledgments

- [Box64](https://github.com/ptitSeb/box64) by ptitSeb
- [SteamCMD](https://developer.valvesoftware.com/wiki/SteamCMD) by Valve
- Ubuntu community

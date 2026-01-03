# Usage Examples

This document provides detailed examples for running various game servers with docker-steam-box64.

## Table of Contents

1. [Basic Setup](#basic-setup)
2. [Valheim Server](#valheim-server)
3. [Palworld Server](#palworld-server)
4. [Custom Game Server](#custom-game-server)
5. [Manual SteamCMD Usage](#manual-steamcmd-usage)

## Basic Setup

### Building the Image

```bash
# Clone the repository
git clone https://github.com/xiahualiu/docker-steam-box64.git
cd docker-steam-box64

# Build the image
docker compose build
```

### Interactive Shell

Start a container with an interactive shell:

```bash
docker compose up -d
docker compose exec steam-box64 bash
```

## Valheim Server

### Quick Start with Script

```bash
# Make sure the script is executable
chmod +x run-valheim.sh

# Run the script
./run-valheim.sh
```

### Manual Setup

1. **Edit docker-compose.yml** - Uncomment the command section for Valheim:

```yaml
services:
  valheim:
    command: >
      bash -c "
      ${STEAMCMDDIR}/steamcmd.sh +force_install_dir /home/steam/valheim-server +login anonymous +app_update 896660 validate +quit &&
      cd /home/steam/valheim-server &&
      box64 ./valheim_server.x86_64 -name '${SERVER_NAME}' -port 2456 -world '${WORLD_NAME}' -password '${SERVER_PASS}' -public ${SERVER_PUBLIC}
      "
```

2. **Configure environment variables** in docker-compose.yml:

```yaml
environment:
  - SERVER_NAME=My Awesome Valheim Server
  - WORLD_NAME=Dedicated
  - SERVER_PASS=strongpassword123
  - SERVER_PUBLIC=1  # Set to 1 for public, 0 for private
```

3. **Start the server**:

```bash
docker compose --profile valheim up -d valheim
```

4. **View logs**:

```bash
docker compose logs -f valheim
```

5. **Stop the server**:

```bash
docker compose --profile valheim down
```

### Valheim Server Configuration

The server files are stored in `./valheim-data/` and configs in `./valheim-config/`.

To modify world settings:
1. Stop the server
2. Edit files in `./valheim-config/`
3. Restart the server

## Palworld Server

### Quick Start with Script

```bash
# Make sure the script is executable
chmod +x run-palworld.sh

# Run the script
./run-palworld.sh
```

### Manual Setup

1. **Edit docker-compose.yml** - Uncomment the command section for Palworld:

```yaml
services:
  palworld:
    command: >
      bash -c "
      ${STEAMCMDDIR}/steamcmd.sh +force_install_dir /home/steam/palworld-server +login anonymous +app_update 2394010 validate +quit &&
      cd /home/steam/palworld-server &&
      box64 ./PalServer.sh
      "
```

2. **Configure environment variables**:

```yaml
environment:
  - SERVER_NAME=My Palworld Server
  - SERVER_DESC=A friendly Palworld server
  - SERVER_PASSWORD=password123
  - ADMIN_PASSWORD=adminpass456
  - MAX_PLAYERS=32
  - SERVER_PORT=8211
  - PUBLIC_PORT=8211
```

3. **Start the server**:

```bash
docker compose --profile palworld up -d palworld
```

4. **View logs**:

```bash
docker compose logs -f palworld
```

## Custom Game Server

Example for 7 Days to Die:

1. **Add a new service** to docker-compose.yml:

```yaml
services:
  7days:
    build: .
    image: steam-box64:latest
    container_name: 7days-server
    environment:
      - SERVER_NAME=My 7DTD Server
      - SERVER_PASSWORD=password
    volumes:
      - ./7days-data:/home/steam/7days-server
    ports:
      - "26900:26900/tcp"
      - "26900:26900/udp"
      - "26901:26901/udp"
      - "26902:26902/udp"
    restart: unless-stopped
    tty: true
    stdin_open: true
    command: >
      bash -c "
      ${STEAMCMDDIR}/steamcmd.sh +force_install_dir /home/steam/7days-server +login anonymous +app_update 294420 validate +quit &&
      cd /home/steam/7days-server &&
      box64 ./7DaysToDieServer.x86_64 -configfile=serverconfig.xml
      "
    profiles:
      - 7days
```

2. **Start the server**:

```bash
docker compose --profile 7days up -d 7days
```

## Manual SteamCMD Usage

### Interactive Shell Access

```bash
docker compose up -d
docker compose exec steam-box64 bash
```

### Download a Game Server

Inside the container:

```bash
# Navigate to SteamCMD directory
cd ~/steamcmd

# Run SteamCMD to download a game server
# Example: Download CS:GO server (App ID: 740)
./steamcmd.sh +force_install_dir ~/csgo-server +login anonymous +app_update 740 validate +quit
```

### Find Steam App IDs

Visit [SteamDB](https://steamdb.info/) and search for the game server you want.

### Running the Server with Box64

```bash
# Navigate to the game server directory
cd ~/your-game-server

# Check if the executable is x86-64
file ./server_executable

# Run with Box64
box64 ./server_executable [arguments]
```

## Common SteamCMD Commands

```bash
# Update a game server
./steamcmd.sh +force_install_dir /path/to/server +login anonymous +app_update <APP_ID> +quit

# Validate/repair game files
./steamcmd.sh +force_install_dir /path/to/server +login anonymous +app_update <APP_ID> validate +quit

# Login with Steam account (for games that require ownership)
./steamcmd.sh +login <username> +force_install_dir /path/to/server +app_update <APP_ID> +quit
```

## Troubleshooting

### Check Box64 Version

```bash
docker compose exec steam-box64 box64 -v
```

### Test Box64 with a Simple Binary

```bash
docker compose exec steam-box64 bash
box64 /usr/bin/file /bin/ls
```

### View Container Logs

```bash
# All logs
docker compose logs

# Specific service
docker compose logs valheim

# Follow logs in real-time
docker compose logs -f valheim
```

### Restart Services

```bash
# Restart specific service
docker compose restart valheim

# Restart all services
docker compose restart
```

### Clean Rebuild

```bash
# Stop all containers
docker compose down

# Remove image
docker rmi steam-box64:latest

# Rebuild from scratch
docker compose build --no-cache

# Start again
docker compose --profile valheim up -d
```

## Performance Tips

1. **CPU Allocation**: ARM64 servers like Ampere A1 have good single-thread performance. Most game servers benefit from 2-4 cores.

2. **Memory**: Allocate at least 4GB RAM for most game servers, 8GB+ for memory-intensive games like Rust or ARK.

3. **Storage**: Use SSD storage for better I/O performance. Game servers can be I/O intensive.

4. **Network**: Ensure your firewall/security groups allow the required ports (both TCP and UDP).

5. **Box64 Tuning**: The Dockerfile includes optimized Box64 environment variables. Modify if needed:

```dockerfile
ENV BOX64_DYNAREC_BIGBLOCK=2  # Try 2 or 3 for better performance
ENV BOX64_DYNAREC_STRONGMEM=0  # Try 0 if game has issues
```

## Common Game Server App IDs

| Game                    | App ID  | Default Ports      |
|-------------------------|---------|-------------------|
| Valheim                 | 896660  | 2456-2458 (UDP)   |
| Palworld                | 2394010 | 8211, 27015 (UDP) |
| 7 Days to Die           | 294420  | 26900-26902       |
| ARK: Survival Evolved   | 376030  | 7777-7778, 27015  |
| Rust                    | 258550  | 28015-28016       |
| CS:GO                   | 740     | 27015, 27020      |
| Team Fortress 2         | 232250  | 27015             |
| Left 4 Dead 2           | 222860  | 27015             |
| Terraria (TShock)       | 105600  | 7777              |
| Project Zomboid         | 380870  | 16261, 8766       |

## Additional Resources

- [Box64 GitHub](https://github.com/ptitSeb/box64)
- [SteamCMD Documentation](https://developer.valvesoftware.com/wiki/SteamCMD)
- [SteamDB - Find App IDs](https://steamdb.info/)
- [Oracle Cloud Free Tier](https://www.oracle.com/cloud/free/)

FROM ubuntu:24.04

LABEL maintainer="docker-steam-box64"
LABEL description="Ubuntu 24.04 with SteamCMD and Box64 for ARM64 game servers"
LABEL architecture="aarch64"

# Build arguments for user ID and group ID
ARG PUID=1000
ARG PGID=1000

# Set environment variables
ENV DEBIAN_FRONTEND=noninteractive \
    LANG=en_US.UTF-8 \
    LANGUAGE=en_US:en \
    LC_ALL=en_US.UTF-8 \
    STEAMCMDDIR=/home/steam/steamcmd \
    BOX64_DIR=/opt/box64 \
    PUID=${PUID} \
    PGID=${PGID}

# Install base dependencies
RUN apt-get update && apt-get install -y \
    software-properties-common \
    curl \
    wget \
    ca-certificates \
    locales \
    git \
    build-essential \
    cmake \
    python3 \
    sudo \
    && locale-gen en_US.UTF-8 \
    && update-locale LANG=en_US.UTF-8 \
    && apt-get clean \
    && rm -rf /var/lib/apt/lists/*

# Add i386 architecture and install SteamCMD dependencies
RUN dpkg --add-architecture i386 \
    && apt-get update \
    && apt-get install -y \
    lib32gcc-s1 \
    lib32stdc++6 \
    libc6:i386 \
    libstdc++6:i386 \
    libgcc-s1:i386 \
    libcurl4:i386 \
    && apt-get clean \
    && rm -rf /var/lib/apt/lists/*

# Create steam user with custom UID/GID
# Note: sudo access is granted to allow Box64 auto-update in entrypoint
# The container runs as root initially to update Box64, then switches to steam user
RUN set -eux; \
    # Check if group with PGID exists, if not create it
    if ! getent group ${PGID} > /dev/null 2>&1; then \
        groupadd -g ${PGID} steam; \
        GROUP_NAME="steam"; \
    else \
        # If group exists, get its name and use it
        GROUP_NAME=$(getent group ${PGID} | cut -d: -f1); \
        echo "Group with GID ${PGID} already exists: ${GROUP_NAME}"; \
    fi; \
    # Check if user with PUID exists
    if getent passwd ${PUID} > /dev/null 2>&1; then \
        # User with this UID exists, get the username
        EXISTING_USER=$(getent passwd ${PUID} | cut -d: -f1); \
        echo "User with UID ${PUID} already exists: ${EXISTING_USER}"; \
        # If it's not named 'steam', create an alias or handle appropriately
        if [ "${EXISTING_USER}" != "steam" ]; then \
            echo "WARNING: UID ${PUID} is already in use by ${EXISTING_USER}. Creating steam user with different UID."; \
            # Create steam user with next available UID but use the group we determined above
            useradd -m -s /bin/bash -g "${GROUP_NAME}" steam; \
        fi; \
    else \
        # Create steam user with specified UID and group
        useradd -m -s /bin/bash -u ${PUID} -g "${GROUP_NAME}" steam; \
    fi; \
    # Grant sudo access
    echo "steam ALL=(ALL) NOPASSWD:ALL" >> /etc/sudoers

# Switch to steam user
USER steam
WORKDIR /home/steam

# Install SteamCMD
RUN mkdir -p "${STEAMCMDDIR}" \
    && cd "${STEAMCMDDIR}" \
    && curl -sqL "https://steamcdn-a.akamaihd.net/client/installer/steamcmd_linux.tar.gz" | tar zxvf - \
    && chmod +x steamcmd.sh

# Switch back to root to install Box64
USER root

# Clone and build Box64
RUN git clone https://github.com/ptitSeb/box64.git "${BOX64_DIR}" \
    && cd "${BOX64_DIR}" \
    && mkdir build \
    && cd build \
    && cmake .. -DARM_DYNAREC=ON -DCMAKE_BUILD_TYPE=RelWithDebInfo \
    && make -j$(nproc) \
    && make install \
    && ldconfig

# Copy and set up entrypoint script for Box64 auto-update
COPY entrypoint.sh /entrypoint.sh
RUN chmod +x /entrypoint.sh

# Set Box64 environment variables for optimal performance
ENV BOX64_NOBANNER=1 \
    BOX64_LOG=0 \
    BOX64_SHOWSEGV=0 \
    BOX64_DYNAREC_BIGBLOCK=1 \
    BOX64_DYNAREC_STRONGMEM=1

# Switch back to steam user
USER steam
WORKDIR /home/steam

# Expose common game server ports (can be overridden in docker-compose)
EXPOSE 27015/tcp 27015/udp 27016/tcp 27016/udp

# Set entrypoint
ENTRYPOINT ["/entrypoint.sh"]
CMD ["/bin/bash"]

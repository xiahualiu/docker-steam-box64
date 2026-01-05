FROM ubuntu:24.04

LABEL maintainer="xiahualiu"
LABEL description="Ubuntu 24.04 with SteamCMD and Box64 for ARM64 game servers"

# By default use UID 1001 for the steam user
ARG USER_UID=1001

ENV DEBIAN_FRONTEND=noninteractive \
    LANG=en_US.UTF-8 \
    BOX64_DIR=/opt/box64 \
    USER_UID=${USER_UID} \
    USER_NAME=steam \
    USER_GROUP=steam

# Recommended Box64 runtime settings
ENV BOX64_NOBANNER=1 \
    BOX64_LOG=1 \
    BOX64_DYNAREC_BIGBLOCK=1 \
    BOX64_DYNAREC_STRONGMEM=1

# Install build/runtime tools and minimal locales
RUN apt-get update \
    && apt-get install -y --no-install-recommends \
       ca-certificates curl wget git build-essential cmake locales python3 \
    # Add game dependencies as needed, e.g., libfreetype6 for Enshrouded Dedicated Server
       libfreetype6 \
    && locale-gen en_US.UTF-8 \
    && update-locale LANG=en_US.UTF-8 \
    && rm -rf /var/lib/apt/lists/*

# Build and install Box64
RUN git clone https://github.com/ptitSeb/box64.git ${BOX64_DIR} \
    && cd ${BOX64_DIR} \
    && mkdir build && cd build \
    && cmake .. -DARM_DYNAREC=ON -DARM64=1 -DBOX32=ON -DCMAKE_BUILD_TYPE=RelWithDebInfo \
    && make -j$(nproc) && make install && ldconfig

# Remove default Ubuntu user/group with UID/GID 1000 to avoid conflicts
RUN if id -u 1000 >/dev/null 2>&1; then \
      USERNAME="$(id -nu 1000)" || USERNAME=""; \
      GROUPNAME="$(getent group 1000 | cut -d: -f1)" || GROUPNAME=""; \
      [ -n "$USERNAME" ] && userdel -r "$USERNAME" 2>/dev/null || true; \
      [ -n "$GROUPNAME" ] && groupdel "$GROUPNAME" 2>/dev/null || true; \
    fi

# Create user with USER_UID
RUN if ! id -u ${USER_UID} >/dev/null 2>&1; then \
        groupadd -g ${USER_UID} ${USER_GROUP} && \
        useradd -m -u ${USER_UID} -g ${USER_GROUP} -s /bin/bash ${USER_NAME}; \
    else \
        echo "User with UID ${USER_UID} already exists, please change USER_UID argument."; \
        exit 1; \
    fi

USER ${USER_NAME}
WORKDIR /home/${USER_NAME}

# GE Proton ENV variables
ENV PROTON_DIR="/home/steam/proton"
ENV PROTON_VERSION="GE-Proton10-27"
ENV PROTON_URL="https://github.com/GloriousEggroll/proton-ge-custom/releases/download/${PROTON_VERSION}/${PROTON_VERSION}.tar.gz" 
ENV PROTON_EXECUTABLE_PATH="${PROTON_DIR}/files/bin/wine64"

# Download and unpack the specified GE-Proton release into the Proton directory
RUN mkdir -p ${PROTON_DIR} \
    && wget -qO- ${PROTON_URL} | tar -xz --strip-components=1 -C ${PROTON_DIR}

# Ensure the Proton wrapper is executable
RUN chmod +x ${PROTON_EXECUTABLE_PATH}

# Create directories for game server files and Proton fixes configuration
RUN mkdir -p /home/${USER_NAME}/.config/protonfixes

# Entrypoint
COPY --chown=${USER_NAME}:${USER_GROUP} entrypoint.sh /entrypoint.sh
RUN chmod +x /entrypoint.sh

ENTRYPOINT ["/entrypoint.sh"]
CMD ["/bin/bash"]

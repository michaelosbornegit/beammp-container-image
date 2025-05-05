####################
#   Build Image    #
####################
FROM docker.io/ubuntu:22.04 AS builder

# Prepare environment
RUN mkdir /work
WORKDIR /work

# Install curl and jq for downloading and parsing release data
RUN apt update && apt upgrade -y && apt install -y curl jq

# Accept build argument to determine if we use pre-releases
ARG PRERELEASE=false

# Get the appropriate release tag based on the PRERELEASE arg
RUN RELEASES_JSON=$(curl -s https://api.github.com/repos/BeamMP/BeamMP-Server/releases) && \
    if [ "$PRERELEASE" = "true" ]; then \
        LATEST_VERSION=$(echo "$RELEASES_JSON" | jq -r '.[0].tag_name'); \
    else \
        LATEST_VERSION=$(echo "$RELEASES_JSON" | jq -r '[.[] | select(.prerelease == false)][0].tag_name'); \
    fi && \
    CURRENT_ARCH=$(uname -m | sed s/aarch64/arm64/g) && \
    CURRENT_OS="ubuntu.22.04" && \
    DOWNLOAD_URL="https://github.com/BeamMP/BeamMP-Server/releases/download/$LATEST_VERSION/BeamMP-Server.$CURRENT_OS.$CURRENT_ARCH" && \
    echo "Downloading $DOWNLOAD_URL" && \
    curl -L -o BeamMP-Server "$DOWNLOAD_URL" && \
    chmod +x BeamMP-Server

# Ensure the executable is present
RUN ls -lsh /work/BeamMP-Server

####################
#    Run Image     #
####################
FROM docker.io/ubuntu:22.04

LABEL maintainer="Rouven Himmelstein <rouven@himmelstein.info>, Michael Osborne <resonatortune@gmail.com>"

# Game server parameter and their defaults
ENV BEAMMP_PORT "30814" \
    BEAMMP_NAME "BeamMP New Server" \
    BEAMMP_MAP "/levels/gridmap_v2/info.json" \
    BEAMMP_DESCRIPTION "BeamMP Default Description" \
    BEAMMP_MAX_CARS "1" \
    BEAMMP_MAX_PLAYERS "10" \
    BEAMMP_PRIVATE "true" \
    BEAMMP_DEBUG "false" \
    BEAMMP_AUTH_KEY "" \
    TZ "UTC"

# Install game server required packages
RUN apt update &&  \
    apt upgrade -y && \
    apt install -y liblua5.3-0 tzdata && \
    apt-get clean && rm -rf /var/lib/apt/lists/

# Create game server folder
RUN mkdir -p /beammp/Resources/Server /beammp/Resources/Client
VOLUME /beammp/Resources/Server
VOLUME /beammp/Resources/Client
WORKDIR /beammp

# Copy the previously downloaded executable
COPY --from=builder /work/BeamMP-Server ./beammp-server

# Prepare user, with uid 1000 and gid 1000
RUN groupadd -g 1000 beammp && \
    useradd -u 1000 -g 1000 -d /beammp -s /bin/bash beammp && \
    chown -R beammp:beammp . &&  \
    chown -R nobody:nogroup /beammp/Resources/ && \
    chmod -R 777 .
USER beammp

# Specify entrypoint
COPY entrypoint.sh .
ENTRYPOINT ["/beammp/entrypoint.sh"]

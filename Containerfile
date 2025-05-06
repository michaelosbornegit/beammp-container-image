####################
#   Build Image    #
####################
FROM docker.io/ubuntu:22.04 AS builder

# Prepare environment
RUN mkdir /work
WORKDIR /work

# Install curl and jq for downloading and parsing release data
RUN apt update && apt upgrade -y && apt install -y curl jq

# Accept build arguments
ARG PRERELEASE=false
ARG VERSION=""

RUN \
  echo "PRERELEASE=$PRERELEASE" && \
  echo "VERSION=$VERSION" && \
  if [ -n "$VERSION" ]; then \
    LATEST_VERSION="$VERSION"; \
  else \
    FILTERED_JSON=$(curl -s https://api.github.com/repos/BeamMP/BeamMP-Server/releases | jq '[.[] | {tag_name, prerelease}]'); \
    if [ "$PRERELEASE" = "true" ]; then \
      LATEST_VERSION=$(echo "$FILTERED_JSON" | jq -r '.[0].tag_name'); \
    else \
      LATEST_VERSION=$(echo "$FILTERED_JSON" | jq -r '[.[] | select(.prerelease == false)][0].tag_name'); \
    fi; \
  fi && \
  echo "$LATEST_VERSION" > version.txt && \
  CURRENT_ARCH=$(uname -m | sed s/aarch64/arm64/g) && \
  CURRENT_OS="ubuntu.22.04" && \
  DOWNLOAD_URL="https://github.com/BeamMP/BeamMP-Server/releases/download/$LATEST_VERSION/BeamMP-Server.$CURRENT_OS.$CURRENT_ARCH" && \
  echo "Downloading $DOWNLOAD_URL" && \
  curl -L -o BeamMP-Server "$DOWNLOAD_URL" && \
  chmod +x BeamMP-Server

# Confirm binary
RUN ls -lsh /work/BeamMP-Server

###############################
# Export-only target for version.txt
###############################
FROM scratch AS version-export
COPY --from=builder /work/version.txt /version.txt

####################
#    Run Image     #
####################
FROM docker.io/ubuntu:22.04

LABEL maintainer="Rouven Himmelstein <rouven@himmelstein.info>, Michael Osborne <resonatortune@gmail.com>"

ENV BEAMMP_PORT="30814" \
    BEAMMP_NAME="BeamMP New Server" \
    BEAMMP_MAP="/levels/gridmap_v2/info.json" \
    BEAMMP_DESCRIPTION="BeamMP Default Description" \
    BEAMMP_MAX_CARS="1" \
    BEAMMP_MAX_PLAYERS="10" \
    BEAMMP_PRIVATE="true" \
    BEAMMP_DEBUG="false" \
    BEAMMP_AUTH_KEY="" \
    TZ="UTC"

RUN apt update && apt upgrade -y && \
    apt install -y liblua5.3-0 tzdata && \
    apt-get clean && rm -rf /var/lib/apt/lists/

# Prepare server directories
RUN mkdir -p /beammp/Resources/Server /beammp/Resources/Client
VOLUME /beammp/Resources/Server
VOLUME /beammp/Resources/Client
WORKDIR /beammp

# Copy built server binary
COPY --from=builder /work/BeamMP-Server ./beammp-server

# Create unprivileged user
RUN groupadd -g 1000 beammp && \
    useradd -u 1000 -g 1000 -d /beammp -s /bin/bash beammp && \
    chown -R beammp:beammp . && \
    chown -R nobody:nogroup /beammp/Resources/ && \
    chmod -R 777 .

USER beammp

COPY entrypoint.sh .
ENTRYPOINT ["/beammp/entrypoint.sh"]

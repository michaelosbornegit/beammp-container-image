## ⚠️ FORKED

RouHim's work is amazing and has been reliable for me for years providing updates to keep my BeamMP servers running.

The original repository stopped automatic weekly builds 3 months ago due to inactivity and the last few builds failed. 

I took the opportunity to fork it to **keep the weekly builds going**, add support for **pre-release builds**, and **more robust image tagging**.

Latest pre-release: `resonatortune/beammp-server:prerelease`
Latest stable: `resonatortune/beammp-server:latest`
I also create tags to pin a version, at the time of making this: `resonatortune/beammp-server:v3.8.3-prerelease` and `resonatortune/beammp-server:v3.4.1`
To view all tags: https://hub.docker.com/repository/docker/resonatortune/beammp-server/tags

existing readme with some tweaks to point to my image links below

---

<p align="center">
  <img src="https://raw.githubusercontent.com/michaelosbornegit/beammp-container-image/main/logo.svg" width="250">
</p>

<p align="center">
    <a href="https://github.com/michaelosbornegit/beammp-container-image/actions/workflows/beammp_release.yml"><img src="https://github.com/michaelosbornegit/beammp-container-image/actions/workflows/beammp_release.yml/badge.svg?branch=main" alt="Stable Release Pipe"></a>
    <a href="https://hub.docker.com/r/resonatortune/beammp-server"><img src="https://img.shields.io/docker/pulls/resonatortune/beammp-server.svg" alt="Docker Hub pulls"></a>
    <a href="https://hub.docker.com/r/resonatortune/beammp-server"><img src="https://img.shields.io/docker/image-size/resonatortune/beammp-server" alt="Docker Hub size"></a>
    <!-- <a href="https://github.com/aquasecurity/trivy"><img src="https://img.shields.io/badge/trivy-protected-blue" alt="trivy"></a> -->
    <a href="https://hub.docker.com/r/resonatortune/beammp-server/tags"><img src="https://img.shields.io/badge/ARCH-amd64_arm64-blueviolet" alt="os-arch"></a>
    <!-- <a href="https://buymeacoffee.com/rouhim"><img alt="Donate me" src="https://img.shields.io/badge/-buy_me_a%C2%A0coffee-gray?logo=buy-me-a-coffee"></a> -->
</p>

<p align="center">
    This project provides a container image for the <a href="https://beammp.com">BeamMP</a> 
    game server and shows its usage in a docker compose environment.
</p>

## Motivation

Because there were no well-documented BeamMP server container images out there, I did one by myself.

## Usage

The sections below provides use cases for docker and docker compose.

### docker

Quick start:

```bash
docker run --name beammp-server \
           -p 30814:30814/tcp -p 30814:30814/udp \
           -e BEAMMP_NAME='My first awesome Server' \
           -e BEAMMP_AUTH_KEY='<insert auth-key>' \
           resonatortune/beammp-server
```

> If you want to interact with the server console, just add the `-it` flag to the docker run command.

### docker compose

First clone this repository and check `docker-compose.yml` if interested. The configuration should be done within
the `.env` file.

To get started rename `.env.example` to `.env` and create the mod folder.

```bash
cp .env.example .env 
mkdir client-mods/ server-mods/
chmod 777 client-mods/ server-mods/
```

> The chmod command is recommended to avoid permission issues.
> The main reason is, that the user in the container, most likely differs from the user on the host.

Adjust the values in the `.env` to your needs and run:

```bash
docker compose pull && docker compose up -d

```

### Server interaction

To connect to the interactive game server console, you need to start the server in detached (docker / -compose `-d`
flag) mode.
Then run the following command to attach to the server console:

```bash
docker attach <container-name>
```

## Environment parameter

| Variable name      | description                                                                                                   | default value                |
|--------------------|---------------------------------------------------------------------------------------------------------------|------------------------------|
| BEAMMP_AUTH_KEY    | Mandatory! The authentication key used by the server. It is used to identify your server and is not optional. | <empty>                      |
| BEAMMP_DEBUG       | Set to true to enable debug output in the console.                                                            | false                        |
| BEAMMP_PRIVATE     | Set to true if you don't want to show up in the Server Browser.                                               | true                         |
| BEAMMP_MAX_CARS    | How many vehicles a player is allowed to have at the same time.                                               | 1                            |
| BEAMMP_MAX_PLAYERS | How many players your server can hold at a time.                                                              | 10                           |
| BEAMMP_MAP         | What the server map is.                                                                                       | /levels/gridmap_v2/info.json |
| BEAMMP_NAME        | What your server is called. This shows up in the Server Browser.                                              | BeamMP New Server            |
| BEAMMP_DESCRIPTION | What shows under the name when you click on the server.                                                       | BeamMP Default Description   |
| BEAMMP_PORT        | This value must be identical to the containers exposed port.                                                  | 30814                        |
| TZ                 | Set the timezone for the container.                                                                           | Utc                          |

A new **auth key** can be claimed on [this site](https://beammp.com/k/dashboard), you will need
a [Discord](https://discord.com) account for this. Note that the IP entered there does *not* matter, despite what the
site claims. For more information refer
to [this wiki page](https://wiki.beammp.com/en/home/server-installation#h-2-obtaining-an-authentication-key).

## Client mods

In the first place you should consider
reading [the official mods guide](https://wiki.beammp.com/en/home/server-installation#how-to-add-mods-to-your-server).
Mods can be downloaded from the [official BeamNG resources website](https://www.beamng.com/resources/). Just copy the
downloaded zip file into the `client-mods` folder.

### Custom maps

Copy the downloaded zip file into the `client-mods` folder.

Then have to find out the custom map path name (e.g.: `/levels/car_jump_arena/info.json`), to set it later as the map to
load. To do so:

1. Execute the shell command below, or open the zip file manually.
2. Copy the absolute path to the `info.json` location (`/levels/{map-name}/info.json`).
3. Set in .env file: `BEAMMP_MAP=/levels/{map-name}/info.json`. Example: `BEAMMP_MAP=/levels/car_jump_arena/info.json`

A simple way to print the full map path including info.json (_unzip_, _grep_ and _awk_ is required):

```shell
unzip -l PATH/TO/MAP.zip \
  | grep 'levels/.*/info.json' \
  | awk '{split($0,a," "); print "/"a[4]}'
```

### Automatic updates

If you want to update the mods automatically, you can use a little tool I wrote called
[beammp-server-beiwagen](https://github.com/michaelosbornegit/beammp-server-beiwagen)
which aims to provide an easy way to update the mods in the `client-mods` folder.

## Server mods

Server mods can be found in the [BeamMP forum](https://forum.beammp.com/c/resource-plugin-area/server-resources).
Installation and configuration instructions are provided by each mod.

### Custom ServerConfig.toml

If you want to specify a custom `ServerConfig.toml` file,
just create a new file called `ServerConfig.toml` and fill it with your
configuration ([Example](https://wiki.beammp.com/en/home/server-installation#h-4-configuration)).
Make sure to mount the file as volume to the container.
The file will be mounted to the server directory on startup.

Docker example:

```bash
docker run --name beammp-server \
           -p 30814:30814/tcp -p 30814:30814/udp \
           -e BEAMMP_NAME='My first awesome Server' \
           -e BEAMMP_AUTH_KEY='<insert auth-key>' \
           -v ./ServerConfig.toml:/beammp/ServerConfig.toml \
           resonatortune/beammp-server
```

For docker compose, just add the following line to the `volumes` section:

```yaml
volumes:
  - ./ServerConfig.toml:/beammp/ServerConfig.toml
```

> Environment variables will always override the values in the `ServerConfig.toml` file.

> Make sure to create the file first, otherwise docker will create a directory instead.

> If you are getting permission errors, you can fix them with: `chmod 777 ServerConfig.toml`

## Resources

- BeamMP server repository: https://github.com/BeamMP/BeamMP-Server
- Official server maintenance guide: https://wiki.beammp.com/en/home/server-maintenance
- Official server installation guide: https://wiki.beammp.com/en/home/server-installation
- Inspired by: https://github.com/mastamic-ian/BeamMP_docker
- Built from: https://github.com/michaelosbornegit/beammp-container-image
- Built to: https://hub.docker.com/r/resonatortune/beammp-server

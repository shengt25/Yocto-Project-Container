# Yocto Docker Development Environment

Building Yocto Project requires numerous files, dependencies, and a Linux environment. This project provides a ready-to-use containerized setup that works out of the box and keeps your host system clean:
- A Yocto container for building 
- A NFS server container to serve the target root filesystem. 

What's more. These two containers can be setup on two hosts, which means a split workflow that you can: 
- build on a powerful remote machine
- serving the NFS rootfs on your computer locally. 

The default target is Beaglebone Black, so you can use it to follow Bootlin’s Yocto training materials, but the environment is generic and not limited to that use case.

Currently the scripts are only for Linux and macOS. On windows you can use `docker compose` command manually for now.

It has persistent volumes for builds, NFS data, and user data. Don't worry about resetting the containers.

## Requirements
- Docker and Docker Compose installed
- At least 100GB of free disk space for Yocto building. 
- `nfs` and `nfsd` module enabled, see below.

`nfs` and `nfsd` module are needed for the nfs server container. On your host machine check with:

```bash
lsmod | grep nfs
```

If you couldn't find `nfs` and `nfsd`, enable them using:

```bash
sudo modprobe nfs 
sudo modprobe nfsd
```

Run the first command again to check it is enabled.

## Setup

### Overview
The Docker Compose will build and run:

Two containers:

1. Yocto Development Environment based on Ubuntu 22.04 with necessary dependencies pre-installed
2. NFS Server providing root filesystem for the target device over network

Three Docker volumes for data persistence:

- `yocto-data` - Stores Yocto lab data and build artifacts
- `yocto-nfs` - Stores NFS server root filesystem data
- `yocto-user` - Stores user configuration in the Yocto container

### Setup

Two options are available:
1. **Local Setup**: Run both Yocto and NFS containers on the same machine
2. **Remote Setup**: Run Yocto container on a powerful remote server and NFS container runs locally.


#### Option 1: Local Setup

```
┌───────────────────────────────────────────┐      ┌──────────────┐
│              Local Machine                │      │  BeagleBone  │
│   ┌─────────────┐         ┌────────────┐  │      │              │
│   │ Yocto Build │         │ NFS Server │◄─┼──────┤  NFS Mount   │
│   │ Container   ├────────►│ Container  │  │      │              │
│   └─────────────┘         └────────────┘  │      │              │
│                                           │      │              │
│                                           │      │              │
└───────────────────────────────────────────┘      └──────────────┘

```
Clone the repository and run the script:
```bash
git clone --recursive https://github.com/shengt25/yocto-docker.git
cd yocto-docker
./run.sh
```

This will build and start both Yocto and NFS containers. After that, the Yocto container will be activated in your terminal.

The container will be stopped when you exit the Yocto container terminal. 

#### Option 2: Remote Setup

```
┌─────────────────────┐                   ┌──────────────────┐      ┌──────────────┐
│  Remote Server      │                   │  Local Machine   │      │  BeagleBone  │
│  ┌───────────────┐  │                   │  ┌────────────┐  │      │              │
│  │ Yocto Build   │  │ update_rootfs.sh  │  │ NFS Server │◄─┼──────┤  NFS Mount   │
│  │ Container     ├──┼─────────────────────►│ Container  │  │      │              │
│  │               │  │                   │  └────────────┘  │      │              │
│  │               │  │ pull_image.sh     │                  │      │              │
│  │               ├──┼──────────────────►│                  │      │              │
│  └───────────────┘  │                   │                  │      │              │
│                     │                   │                  │      │              │
└─────────────────────┘                   └──────────────────┘      └──────────────┘
```

**On Remote Server:**

Clone the repository and start the Yocto container:
```bash
git clone --recursive https://github.com/shengt25/yocto-docker.git
cd yocto-docker/remote-setup
./run_yocto.sh
```

This will build and start Yocto container on the remote server. The container will be activated in your terminal.

The container will be stopped when you exit the Yocto container terminal. 

**On Local Machine:**

Clone the repository and start the NFS server:
```bash
git clone --recursive https://github.com/shengt25/yocto-docker.git
cd yocto-docker/remote-setup
./run_nfs.sh
```
The NFS server container will run in the foreground, press `Ctrl+C` to stop it.

**Pull the Image:**

If you want to pull built images (`wic.xz` format) to your local machine, which can be flashed to an SD card, run:

```bash
./pull_image.sh <remote-user>@<remote-ip>
```
Options:  
```
Use `-i` to specify image name prefix. Full image name will be <prefix>-beaglebone.rootfs.tar.xz (default prefix: core-image-minimal).   
Use `-y` to Skip confirmation prompt.  
Use `-h` flag for help.
```

**Update Root Filesystem:**

If you want to directly update the root filesystem served by the local NFS server, run:
```bash
./update_rootfs.sh <remote-user>@<remote-ip>
```
This will fetch the latest root filesystem from the remote server's container and update it to the local NFS container.

Options:  
```
Use `-i` to specify image name prefix. Full image name will be <prefix>-beaglebone.rootfs.wic.xz (default prefix: core-image-minimal).   
Use `-y` to Skip confirmation prompt.  
Use `-h` flag for help.
```

## Acknowledgements

The NFS server container is based on [obeone/docker-nfs-server](https://github.com/obeone/docker-nfs-server), which is forked and improved upon [ehough/docker-nfs-server](https://github.com/ehough/docker-nfs-server)

The development environment setup is inspired by [antonsaa/yocto-dev](https://gitlab.metropolia.fi/antonsaa/yocto-dev)

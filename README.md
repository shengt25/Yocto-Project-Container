# Yocto Docker Development Environment

A containerized environment for learning Yocto Project and OpenEmbedded development, based on Bootlin's training materials.

## Why Use This?

Building Yocto Project requires numerous files, dependencies, and a Linux environment. This project provides a ready-to-use containerized setup that:
- Works out of the box
- Keeps your host system clean
- Follows Bootlin's training materials

Currently supports macOS and Linux, with BeagleBone Black as the target hardware platform. Feel free to modify for your own hardware, or wait for future updates with more flexible configuration.


## Lab Environment Setup

### Requirements
- Docker and Docker Compose installed
- For Yocto builds: At least 100GB of free disk space
- For scripts, they are supported on Linux or macOS. For Windows consider using WSL2, or you can run the containers manually using Docker commands.
  
### Overview
This repository provides a Dockerized development environment consisting of two containers:

1. Yocto Development Environment based on Ubuntu 22.04 with necessary dependencies pre-installed
2. NFS Server providing root filesystem for the target device over network

The containers use three Docker volumes for data persistence:

- `yocto-data` - Stores Yocto lab data and build artifacts
- `yocto-nfs` - Stores NFS server root filesystem data
- `yocto-user` - Stores user configuration in the Yocto container

### Setup

Two options are available:
1. **Local Setup**: Run both Yocto and NFS containers on the same machine
2. **Remote Setup**: Run Yocto container on a remote server and NFS container locally. This is useful if your local machine has limited resources but you have access to a more powerful remote server

The details for each option are provided below.

#### For Both Options

These are some notes to keep in mind, for both options.

**Yocto development container**

- The container will be automatically shutdown when you exit the terminal of Yocto development container. All settings and data are preserved (container is stopped, not removed). To reset the container, run `rebuild_yocto.sh`.

- Inside the container, you will be logged in as user `yocto` (password: `yocto`).
- The `/nfs` directory is already mounted inside the Yocto container, so don't worry about the NFS setup in labs. Follow the rest of the tutorial to build images.

**NFS server**

- We are using NFSv4 while the labs uses NFSv3. When configuring the NFS mount on the target device, simply change `nfsvers=3` to `nfsvers=4`, when appending mount options in `extlinux/extlinux.conf.`
- You might need to change your firewall settings to let the NFS server accept incoming connections (from beaglebone). See Firewall Settings.

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

**Usage:**
Clone the repository and run the script:
```bash
git clone --recursive https://github.com/shengt25/yocto-docker.git
cd Learn-Yocto-Project
./run.sh
```

This will build and start both Yocto and NFS containers. After that, the Yocto container will be activated in your terminal.

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
cd Learn-Yocto-Project/remote-setup
./run_yocto.sh
```

This will build and start Yocto container on the remote server. The container will be activated in your terminal.

**On Local Machine:**

Clone the repository and start the NFS server:
```bash
git clone --recursive https://github.com/shengt25/yocto-docker.git
cd Learn-Yocto-Project/remote-setup
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
This project follows Bootlin's Yocto Project training materials.

The NFS server container is based on [obeone/docker-nfs-server](https://github.com/obeone/docker-nfs-server), which is forked and improved upon [ehough/docker-nfs-server](https://github.com/ehough/docker-nfs-server)

The development environment setup is inspired by [antonsaa/yocto-dev](https://gitlab.metropolia.fi/antonsaa/yocto-dev)

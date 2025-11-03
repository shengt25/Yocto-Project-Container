# Learn Yocto Project

This is a learning project for Yocto Project and OpenEmbedded development training, following Bootlin's training materials: https://bootlin.com/training/yocto/. You can see the Slides and Practical Labs in this link.
The target hardware platform is BeagleBone Black.


## Lab Environment Setup

### Requirements
- Docker and Docker Compose installed
- For Yocto builds: At least 100GB of free disk space
- For scripts, they are supported on Linux or macOS. For Windows consider using WSL2, or you can run the containers manually using Docker commands.
  
### Overview
This repository provides a Dockerized development environment consisting of two containers:

1. Yocto Development Environment based on Ubuntu 22.04 with necessary dependencies pre-installed
2. NFS Server providing root filesystem for the target device over network

**Note that we are using NFSv4**, while the labs uses NFSv3. When configuring the NFS mount on the target device, simply change `nfsvers=3` to `nfsvers=4`.

The containers use three Docker volumes for data persistence:

- `yocto-data` - Stores Yocto lab data and build artifacts
- `yocto-nfs` - Stores NFS server root filesystem data
- `yocto-user` - Stores user configuration in the Yocto container

### Usage Options

Two options are available:
1. **Local Setup**: Run both Yocto and NFS containers on the same machine
2. **Remote Setup**: Run Yocto container on a remote server and NFS container locally. This is useful if your local machine has limited resources but you have access to a more powerful remote server

The details for each option are provided below.

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
git clone https://github.com/shengt25/Learn-Yocto-Project.git
cd Learn-Yocto-Project
./run.sh
```

This will build and start both Yocto and NFS containers. After that, the Yocto container will be activated in your terminal.

The `/nfs` directory is already mounted inside the Yocto container, so don't worry about the NFS setup in labs. Follow the rest of the tutorial to build images.

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
git clone https://github.com/shengt25/Learn-Yocto-Project.git
cd Learn-Yocto-Project/remote-setup
./run_yocto.sh
```

Then you can build the Yocto images inside the container

**On Local Machine:**

Clone the repository and start the NFS server:
```bash
git clone https://github.com/shengt25/Learn-Yocto-Project.git
cd Learn-Yocto-Project/remote-setup
./run_nfs.sh
```

**Pull the Image:**

If you want to pull built images (`wic.xz` format) to your local machine, which can be flashed to an SD card, run:

```bash
./pull_image.sh <remote-user>@<remote-ip>
```
Use `-h` flag for help.

**Update Root Filesystem:**

If you want to directly update the root filesystem served by the local NFS server, run:
```bash
./update_rootfs.sh <remote-user>@<remote-ip>
```
This will fetch the latest root filesystem from the remote server's container and update it to the local NFS container.
Use `-h` flag for help.

## Acknowledgements
This project follows Bootlin's Yocto Project training materials.

The NFS server container is based on [obeone/docker-nfs-server](https://github.com/obeone/docker-nfs-server), which is forked and improved upon [ehough/docker-nfs-server](https://github.com/ehough/docker-nfs-server)

The development environment setup is inspired by [antonsaa/yocto-dev](https://gitlab.metropolia.fi/antonsaa/yocto-dev)
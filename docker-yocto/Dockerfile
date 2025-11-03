FROM ubuntu:22.04

ARG DEBIAN_FRONTEND=noninteractive

RUN apt update && \
    apt upgrade -y && \
    apt install gawk wget git diffstat unzip texinfo gcc build-essential \
    chrpath socat cpio python3 python3-pip python3-pexpect xz-utils debianutils \
    iputils-ping python3-git python3-jinja2 python3-subunit zstd liblz4-tool file \
    locales libacl1 \
    # above are copied from bootlin yocto docs, required for building
    sudo nano zsh tree vim curl -y && \
    apt clean && \
    rm -rf /var/lib/apt/lists/*


RUN useradd -ms /bin/zsh yocto && \
    usermod -aG sudo yocto && \
    echo "yocto:yocto" | chpasswd && \
    echo "en_US.UTF-8 UTF-8" > /etc/locale.gen && \
    locale-gen && \
    mkdir -m 777 /nfs

ENV LANG=en_US.utf8
ENV TERM=xterm-256color

USER yocto
WORKDIR /home/yocto

RUN sh -c "$(wget -O- https://github.com/deluan/zsh-in-docker/releases/download/v1.2.1/zsh-in-docker.sh)" -- \
    -x \
    -p https://github.com/zsh-users/zsh-autosuggestions \
    -p https://github.com/zsh-users/zsh-completions \
    -p https://github.com/zsh-users/zsh-syntax-highlighting

# Configure git, needed for applying patches
RUN git config --global user.email "yocto@example.com" && \
    git config --global user.name "yocto"

# Create user dir and download Yocto data from Bootlin
RUN mkdir $HOME/user && \
    wget https://bootlin.com/doc/training/yocto/yocto-labs.tar.xz && \
    tar xvf yocto-labs.tar.xz && rm yocto-labs.tar.xz

ENTRYPOINT ["/bin/sh", "-c", "while :; do sleep 2073600 & wait; done"]
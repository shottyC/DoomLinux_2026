FROM mcr.microsoft.com/devcontainers/base:ubuntu

ENV DEBIAN_FRONTEND=noninteractive

RUN apt-get update && apt-get install -y \
    wget \
    curl \
    make \
    gawk \
    gcc \
    bc \
    bison \
    flex \
    unzip \
    rsync \
    mtools \
    xorriso \
    libelf-dev \
    libssl-dev \
    grub-common \
    grub-pc-bin \
    grub-efi-amd64-bin \
    cpio \
    tar \
    xz-utils \
    file \
    dosfstools \
    qemu-system-x86-headless \
    vagrant \
    docker.io \
    shellcheck \
    shfmt \
    python3 \
    python3-pip \
    && rm -rf /var/lib/apt/lists/*

RUN pip3 install --no-cache-dir behave coverage

RUN usermod -aG docker vscode

WORKDIR /workspace

# Devcontainer base
FROM mcr.microsoft.com/devcontainers/base:ubuntu

# Set non-interactive mode for apt
ENV DEBIAN_FRONTEND=noninteractive

# Install dependencies
RUN apt-get update && apt-get install -y software-properties-common \
    && add-apt-repository universe \
    && apt-get update \
    && apt-get install -y \
        wget curl make gawk gcc bc bison flex unzip rsync mtools \
        xorriso libelf-dev libssl-dev grub-common grub-pc-bin \
        grub-efi-amd64-bin cpio tar xz-utils file dosfstools \
        qemu-system-x86 docker.io shellcheck shfmt \
        python3 python3-pip \
    # Install Vagrant from HashiCorp repo
    && curl -fsSL https://apt.releases.hashicorp.com/gpg | gpg --dearmor -o /usr/share/keyrings/hashicorp-archive-keyring.gpg \
    && echo "deb [signed-by=/usr/share/keyrings/hashicorp-archive-keyring.gpg] https://apt.releases.hashicorp.com $(lsb_release -cs) main" \
       | tee /etc/apt/sources.list.d/hashicorp.list \
    && apt-get update \
    && apt-get install -y vagrant \
    # Clean up
    && rm -rf /var/lib/apt/lists/*

# Make DoomLinux.sh executable (optional if you add it later)
WORKDIR /workspace
COPY DoomLinux.sh /workspace/DoomLinux.sh
RUN chmod +x /workspace/DoomLinux.sh

# Install Python dev dependencies
RUN pip3 install behave

# Set default shell
SHELL ["/bin/bash", "-c"]

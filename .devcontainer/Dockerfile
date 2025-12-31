# Devcontainer base
FROM mcr.microsoft.com/devcontainers/base:ubuntu

# Set non-interactive mode for apt
ENV DEBIAN_FRONTEND=noninteractive

# Install system dependencies
RUN apt-get update && apt-get install -y software-properties-common \
    && add-apt-repository universe \
    && apt-get update \
    && apt-get install -y \
        wget curl make gawk gcc bc bison flex unzip rsync mtools \
        xorriso libelf-dev libssl-dev grub-common grub-pc-bin \
        grub-efi-amd64-bin cpio tar xz-utils file dosfstools \
        qemu-system-x86 docker.io shellcheck shfmt \
        python3 python3-venv python3-pip \
    # Install Vagrant from HashiCorp repo
    && curl -fsSL https://apt.releases.hashicorp.com/gpg \
        | gpg --dearmor -o /usr/share/keyrings/hashicorp-archive-keyring.gpg \
    && echo "deb [signed-by=/usr/share/keyrings/hashicorp-archive-keyring.gpg] \
        https://apt.releases.hashicorp.com $(lsb_release -cs) main" \
        > /etc/apt/sources.list.d/hashicorp.list \
    && apt-get update \
    && apt-get install -y vagrant \
    # Clean up
    && rm -rf /var/lib/apt/lists/*

# Create a Python virtual environment for dev tools
RUN python3 -m venv /opt/venv

# Upgrade pip and install Python dev dependencies inside venv
RUN /opt/venv/bin/pip install --upgrade pip \
    && /opt/venv/bin/pip install behave coverage

# Make venv Python the default
ENV PATH="/opt/venv/bin:$PATH"

# Workspace setup
WORKDIR /workspace
COPY DoomLinux.sh /workspace/DoomLinux.sh
RUN chmod +x /workspace/DoomLinux.sh

# Set default shell
SHELL ["/bin/bash", "-c"]


FROM ubuntu:20.04

SHELL ["/bin/bash", "-c"]

# Install system packages.
RUN (yes | unminimize) && \
    DEBIAN_FRONTEND=noninteractive apt-get install -y \
      build-essential \
      ccache \
      curl \
      git \
      ninja-build \
      software-properties-common \
      sudo \
      vim && \
    # Install Python 3.9.
    add-apt-repository ppa:deadsnakes/ppa -y && apt-get update && apt-get install -y python3.9 && \
    ln -s /usr/bin/python3 /usr/bin/python && \
    # Install Node.js 16.
    (curl -fsSL https://deb.nodesource.com/setup_16.x | bash -) && \
    apt-get install -y nodejs && \
    # Create ccache symlinks.
    /usr/sbin/update-ccache-symlinks && \
    # Delete apt cache.
    rm -rf /var/lib/apt/lists/*

# Create nodejs user.
RUN adduser --disabled-password --gecos "" nodejs && \
    usermod -aG sudo nodejs

USER nodejs

# Setup npm and install global packages.
RUN mkdir ~/.npm-global && \
    npm config set prefix '~/.npm-global' && \
    npm install -g node-core-utils

# Add ccache and npm global packages to PATH
ENV PATH ~/.npm-global/bin:/usr/lib/ccache:$PATH

# Setup Node.js repository
RUN git clone --origin upstream https://github.com/nodejs/node.git /home/nodejs/node

WORKDIR /home/nodejs/node

RUN ncu-config set upstream upstream && \
    ncu-config set branch master

# Prebuild Node.js
RUN python configure.py \
      --ninja \
      --node-builtin-modules-path /home/nodejs/node && \
    ninja -C out/Release -j 2

FROM ubuntu:20.04

# Install system packages.
RUN (yes | unminimize) && \
    DEBIAN_FRONTEND=noninteractive apt-get install -y curl git build-essential ninja-build ccache software-properties-common && \
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
RUN adduser --disabled-password --gecos "" nodejs

USER nodejs

# Setup npm and install global packages.
RUN mkdir ~/.npm-global && \
    npm config set prefix '~/.npm-global' && \
    npm install -g node-core-utils

# Setup Node.js repository
RUN git clone https://github.com/nodejs/node.git /home/nodejs/node

WORKDIR /home/nodejs/node

# Add ccache and npm global packages to PATH
ENV PATH ~/.npm-global/bin:/usr/lib/ccache:$PATH

# Prebuild Node.js
RUN python configure.py --ninja && \
    ninja -C out/Release -j 2 && \
    make test && \
    # Remove large build artifacts to make the image lighter. ccache will help to rebuild things fast.
    rm -rf out/Release/obj && \
    rm -f out/Release/*.a && \
    rm -rf out/Release/gen

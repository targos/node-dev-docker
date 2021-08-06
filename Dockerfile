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
RUN adduser --disabled-password --gecos "" nodejs && \
    # Setup ccache for nodejs user.
    echo 'export PATH="/usr/lib/ccache:$PATH"' | tee -a /home/nodejs/.bashrc

USER nodejs

# Setup npm and install global packages.
RUN mkdir ~/.npm-global && \
    npm config set prefix '~/.npm-global' && \
    echo 'export PATH="~/.npm-global/bin:$PATH"' | tee -a /home/nodejs/.bashrc && \
    npm install -g node-core-utils

# Setup Node.js repository
RUN git clone https://github.com/nodejs/node.git /home/nodejs/node

WORKDIR /home/nodejs/node

SHELL ["/bin/bash", "-c"]

# Prebuild Node.js
RUN source $HOME/.bashrc && \
    python configure.py --ninja && ninja -C out/Release -j 2 && \
    make test
    # Remove build artifacts to make the image lighter. ccache will help to rebuild things fast.
    # TODO: It seems that ninja isn't used in the previous command...
    # rm -rf out/

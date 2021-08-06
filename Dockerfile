FROM ubuntu:20.04

RUN (yes | unminimize) && \
    DEBIAN_FRONTEND=noninteractive apt-get install -y curl git build-essential ccache software-properties-common && \
    # Install Python 3.9
    add-apt-repository ppa:deadsnakes/ppa -y && apt-get update && apt-get install -y python3.9 && \
    # Install Node.js 16
    (curl -fsSL https://deb.nodesource.com/setup_16.x | bash -) && \
    apt-get install -y nodejs && \
    # Create ccache symlinks
    /usr/sbin/update-ccache-symlinks && \
    # Create nodejs user.
    adduser --disabled-password --gecos "" nodejs && \
    # Setup ccache for nodejs user.
    echo 'export PATH="/usr/lib/ccache:$PATH"' | tee -a /home/nodejs/.bashrc

USER nodejs

# Setup npm
RUN mkdir ~/.npm-global && \
    npm config set prefix '~/.npm-global' && \
    echo 'export PATH="~/.npm-global/bin:$PATH"' | tee -a /home/nodejs/.bashrc && \
    npm install -g node-core-utils

# Setup Node.js repository
RUN git clone https://github.com/nodejs/node.git /home/nodejs/node
WORKDIR /home/nodejs/node

# Prebuild Node.js
RUN ./configure && make -j2 V=

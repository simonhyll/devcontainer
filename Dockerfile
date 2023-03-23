# Arguments for the Node.js version to install along with npm, yarn and pnpm
ARG NODE_VERSION="18"

# Argument for the mold linker version to install
ARG MOLD_VERSION="v1.4.2"

# Argument for the branch to use for the Tauri CLI
ARG TAURI_CLI_VERSION="next"

# Arguments related to setting up a non-root user for the container
ARG USERNAME=vscode
ARG USER_UID=1000
ARG USER_GID=$USER_UID

# Arguments for installing dependencies where DEPENDENCIES are Tauri dependencies and EXTRA_DEPENDENCIES is empty so that users can add more without interfering with Tauri
ARG TAURI_DEPENDENCIES="libwebkit2gtk-4.0-dev build-essential curl wget libssl-dev libgtk-3-dev libayatana-appindicator3-dev librsvg2-dev"
ARG EXTRA_DEPENDENCIES=""

# Argument for which image version to use
ARG IMAGE="mcr.microsoft.com/vscode/devcontainers/base"
ARG VARIANT="0-ubuntu-22.04"

######################################
## Base image
## Installing dependencies
######################################
FROM ${IMAGE}:${VARIANT} AS base_image

# Redefine arguments
ARG TAURI_DEPENDENCIES
ARG EXTRA_DEPENDENCIES

# Non-interactive frontend
ENV DEBIAN_FRONTEND=noninteractive

# Install dependencies
RUN apt update \
    && apt upgrade -yq \
    # Install general dependencies
    && apt install -yq --no-install-recommends sudo default-jdk \
    wget curl xz-utils zip unzip file socat clang libssl-dev \
    pkg-config git git-lfs bash-completion llvm \
    # Install Tauri dependencies as well as extra dependencies
    && apt install -yq ${TAURI_DEPENDENCIES} ${EXTRA_DEPENDENCIES}

######################################
## Mold
## Speeds up compilation
######################################
FROM base_image as mold
WORKDIR /mold

# Redefine arguments
ARG MOLD_VERSION

# Install dependencies
RUN apt update \
    && apt install -yq g++ libstdc++-10-dev zlib1g-dev cmake

# Clone mold 1.4.2, build it then install it
RUN git clone https://github.com/rui314/mold.git \
    && cd mold \
    && git checkout --quiet ${MOLD_VERSION} \
    && make -j$(nproc) CXX=clang++ \
    && make install

# Set up a config.toml file that makes Cargo use clang and mold
RUN echo "[target.x86_64-unknown-linux-gnu]" >> /config.toml \
    && echo "linker = \"clang\"" >> /config.toml \
    && echo "rustflags = [\"-C\", \"link-arg=-fuse-ld=/usr/local/bin/mold\"]" >> /config.toml

######################################
## Tauri CLI
## Temporary workaround
######################################
FROM base_image as tauri-cli
WORKDIR /build

# Redefinte arguments
ARG TAURI_CLI_VERSION

# Install rustup
RUN curl https://sh.rustup.rs -sSf | \
    sh -s -- --default-toolchain stable -y

# Add Cargo bin to the PATH
ENV PATH="/home/${USERNAME}/.cargo/bin:$PATH"

# Build and install the Tauri CLI
RUN . ~/.cargo/env \
    && git clone https://github.com/tauri-apps/tauri \
    && cd tauri/tooling/cli \
    && git checkout ${TAURI_CLI_VERSION} \
    && cargo build \
    && cp target/debug/cargo-tauri /cargo-tauri

######################################
## The finalized container
## Puts it all together
######################################
FROM base_image

# Redefine args
ARG USERNAME
ARG USER_UID
ARG USER_GID

ARG NODE_VERSION

# Ensure the user is a sudo user in case the developer needs to e.g. run apt install later
RUN echo $USERNAME ALL=\(root\) NOPASSWD:ALL > /etc/sudoers.d/$USERNAME \
    && chmod 0440 /etc/sudoers.d/$USERNAME

# Install Node.js
RUN curl -sL "https://deb.nodesource.com/setup_${NODE_VERSION}.x" | bash -E - \
    && apt update \
    && apt install -yq nodejs \
    && npm i -g npm \
    && npm i -g yarn pnpm \
    && SHELL=bash pnpm setup

# Clean up to reduce container size
RUN apt clean \
    && rm -rf /var/lib/apt/lists/*

# Run the rest of the commands as the non-root user
USER $USERNAME

# Install rustup
RUN curl https://sh.rustup.rs -sSf | \
    sh -s -- --default-toolchain stable -y

# Ensure the Cargo env gets loaded
RUN echo "source /home/${USERNAME}/.cargo/env" >>/home/${USERNAME}/.bashrc

# Add Cargo bin to the PATH, primarily to ensure the next command can find rustup
ENV PATH="/home/${USERNAME}/.cargo/bin:$PATH"

# Update Rust and install required Android targets
RUN rustup update \
    # Add WASM support
    && rustup target add wasm32-unknown-unknown

# Install Trunk
RUN cargo install trunk --git https://github.com/amrbashir/trunk

# Copy files from mold
COPY --from=mold --chown=${USERNAME}:${USERNAME} /usr/local/bin/mold /usr/local/bin/mold
COPY --from=mold --chown=${USERNAME}:${USERNAME} /config.toml /home/${USERNAME}/.cargo/config.toml

# Install the Tauri CLI
COPY --from=tauri-cli --chown=${USERNAME}:${USERNAME} /cargo-tauri /usr/local/bin/cargo-tauri

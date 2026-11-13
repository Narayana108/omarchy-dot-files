
FROM docker.io/library/debian:13-slim

ARG NODE_VERSION=26.13.0
ARG GO_VERSION=1.27.4
ARG GO_SHA256=7226736c2339719cda28fbf3a54d71aa63bcefe376e98cef00034268dab24840
ARG BUN_VERSION=1.4.4

ENV DEBIAN_FRONTEND=noninteractive

# System packages and development dependencies
RUN apt-get update && apt-get install -y --no-install-recommends \
    bash \
    ca-certificates \
    curl \
    git \
    openssh-client \
    build-essential \
    pkg-config \
    python3 \
    python3-dev \
    python3-venv \
    python3-pip \
    jq \
    procps \
    ripgrep \
    unzip \
    xz-utils \
    libatomic1 \
    passwd \
    && rm -rf /var/lib/apt/lists/*

# Install Node.js and npm from official binaries
RUN set -eux; \
    cd /tmp; \
    NODE_ARCHIVE="node-v${NODE_VERSION}-linux-x64.tar.xz"; \
    curl -fsSLO "https://nodejs.org/dist/v${NODE_VERSION}/${NODE_ARCHIVE}"; \
    curl -fsSLO "https://nodejs.org/dist/v${NODE_VERSION}/SHASUMS256.txt"; \
    grep " ${NODE_ARCHIVE}$" SHASUMS256.txt | sha256sum -c -; \
    tar -xJf "${NODE_ARCHIVE}" \
        -C /usr/local \
        --strip-components=1 \
        --no-same-owner; \
    rm -f "${NODE_ARCHIVE}" SHASUMS256.txt

# Install Go from official binaries and verify checksum
RUN set -eux; \
    curl -fsSLo /tmp/go.tar.gz \
        "https://go.dev/dl/go${GO_VERSION}.linux-amd64.tar.gz"; \
    echo "${GO_SHA256}  /tmp/go.tar.gz" | sha256sum -c -; \
    tar -C /usr/local -xzf /tmp/go.tar.gz; \
    rm /tmp/go.tar.gz

# Create unprivileged development user
RUN groupadd --gid 1000 dev \
    && useradd \
        --uid 1000 \
        --gid 1000 \
        --create-home \
        --shell /bin/bash \
        dev

RUN install -d -o dev -g dev -m 0700 \
    /home/dev/.omp \
    /home/dev/.omp/agent \
    /home/dev/.omp/run \
    /home/dev/.config \
    /home/dev/.config/opencode \
    /home/dev/.local \
    /home/dev/.local/share \
    /home/dev/.local/share/opencode \
    /home/dev/.npm-global \
    /home/dev/.npm-global/bin \
    /home/dev/.qoder

# Development environment
ENV HOME=/home/dev
ENV BUN_INSTALL=/home/dev/.bun
ENV GOPATH=/home/dev/go
ENV GOMODCACHE=/home/dev/go/pkg/mod
ENV NPM_CONFIG_PREFIX=/home/dev/.npm-global

ENV PATH="/home/dev/.bun/bin:/home/dev/.npm-global/bin:/home/dev/.opencode/bin:/home/dev/go/bin:/usr/local/go/bin:/usr/local/bin:/usr/bin:/bin"

# Run development tools as unprivileged user
USER dev

# Install Bun and OMP
RUN curl -fsSL https://bun.com/install | bash -s "bun-v${BUN_VERSION}" \
    && bun install -g @oh-my-pi/pi-coding-agent

# Install OpenCode and Qoder at upstream latest (resolved at build time)
RUN curl -fsSL https://opencode.ai/install | bash -s -- --no-modify-path \
    && opencode --version

# The qoder npm dispatcher self-bootstraps into $HOME/.qoder and rewrites the
# shell rc on first run. Run both steps against a throwaway HOME so the image
# keeps /home/dev/.qoder a pure mount target and /home/dev/.profile untouched.
RUN mkdir -p /tmp/qoder-check \
    && HOME=/tmp/qoder-check QODER_CONFIG_DIR=/tmp/qoder-check \
       npm install -g "@qoder-ai/qodercli@latest" \
    && HOME=/tmp/qoder-check QODER_CONFIG_DIR=/tmp/qoder-check qoder --version \
    && rm -rf /tmp/qoder-check

WORKDIR /workspace

CMD ["bash"]


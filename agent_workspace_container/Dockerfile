
FROM docker.io/library/debian:13-slim

ARG NODE_VERSION=26.13.0
ARG GO_VERSION=1.27.4
ARG GO_SHA256=7226736c2339719cda28fbf3a54d71aa63bcefe376e98cef00034268dab24840
ARG BUN_VERSION=1.4.4
ARG GH_VERSION=2.104.0
ARG GH_SHA256=98cb101ad87dbbd3f6b2f2bfcbd43197ccd07643140121d8a9cfaa91eadbc24e
ARG OMP_VERSION=18.20.3
ARG OPENCODE_VERSION=1.19.5
ARG QODER_VERSION=1.1.90
ARG WP_CLI_VERSION=2.12.0
ARG WP_CLI_SHA256=ce34ddd838f7351d6759068d09793f26755463b4a4610a5a5c0a97b68220d85c
ARG PHPSTAN_VERSION=2.3.6
ARG PHPSTAN_SHA256=bd5af896c8eb831e10873a4407c37ac33118dcd88de4ea77e13cd6e6702a41cc
ARG PHP_CS_FIXER_VERSION=3.95.31
ARG PHP_CS_FIXER_SHA256=4c4fb157a6adf633ef130abda3bf208c81918af941404bc169d16081fdfaea8d
ARG SQLS_VERSION=0.2.48
ARG SQLS_SHA256=30047b92c41658c821b7803d2c2a3a1ce4e17ee769ceff6f24bb9e3daaf5d4dc

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
    ncurses-term \
    kitty-terminfo \
    foot-terminfo \
    less \
    file \
    xxd \
    tree \
    fd-find \
    bat \
    fzf \
    sqlite3 \
    bc \
    time \
    moreutils \
    parallel \
    entr \
    inotify-tools \
    pv \
    rsync \
    wget \
    gnupg \
    git-lfs \
    dnsutils \
    netcat-openbsd \
    lsof \
    strace \
    tmux \
    vim \
    zip \
    zstd \
    bzip2 \
    tokei \
    git-filter-repo \
    git-delta \
    just \
    yq \
    shellcheck \
    shfmt \
    clangd \
    clang-format \
    gopls \
    rust-analyzer \
    cargo \
    rustc \
    rubocop \
    yamllint \
    ansible-lint \
    php-cli \
    php-mbstring \
    php-xml \
    php-curl \
    php-zip \
    php-gd \
    php-intl \
    php-sqlite3 \
    php-mysql \
    php-pgsql \
    php-tokenizer \
    composer \
    phpunit \
    && rm -rf /var/lib/apt/lists/*

# Debian ships fd and bat under conflict-avoiding names.
RUN ln -sf /usr/bin/fdfind /usr/local/bin/fd \
    && ln -sf /usr/bin/batcat /usr/local/bin/bat

# Python tooling the agent reaches for constantly.
RUN python3 -m pip install --no-cache-dir --break-system-packages \
    uv ruff sqlfluff "python-lsp-server[all]"

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

# Install GitHub CLI (gh) from the official release tarball and verify checksum
RUN set -eux; \
    cd /tmp; \
    GH_ARCHIVE="gh_${GH_VERSION}_linux_amd64.tar.gz"; \
    curl -fsSLO "https://github.com/cli/cli/releases/download/v${GH_VERSION}/${GH_ARCHIVE}"; \
    echo "${GH_SHA256}  ${GH_ARCHIVE}" | sha256sum -c -; \
    tar -xzf "${GH_ARCHIVE}" -C /usr/local --strip-components=1 --no-same-owner; \
    rm -f "${GH_ARCHIVE}"; \
    gh --version

# WordPress CLI, PHPStan, and PHP-CS-Fixer from pinned release phars.
RUN set -eux; \
    cd /tmp; \
    curl -fsSLo wp-cli.phar \
        "https://github.com/wp-cli/wp-cli/releases/download/v${WP_CLI_VERSION}/wp-cli-${WP_CLI_VERSION}.phar"; \
    echo "${WP_CLI_SHA256}  wp-cli.phar" | sha256sum -c -; \
    install -m 0755 wp-cli.phar /usr/local/bin/wp; \
    curl -fsSLo phpstan.phar \
        "https://github.com/phpstan/phpstan/releases/download/${PHPSTAN_VERSION}/phpstan.phar"; \
    echo "${PHPSTAN_SHA256}  phpstan.phar" | sha256sum -c -; \
    install -m 0755 phpstan.phar /usr/local/bin/phpstan; \
    curl -fsSLo php-cs-fixer.phar \
        "https://github.com/PHP-CS-Fixer/PHP-CS-Fixer/releases/download/v${PHP_CS_FIXER_VERSION}/php-cs-fixer.phar"; \
    echo "${PHP_CS_FIXER_SHA256}  php-cs-fixer.phar" | sha256sum -c -; \
    install -m 0755 php-cs-fixer.phar /usr/local/bin/php-cs-fixer; \
    rm -f wp-cli.phar phpstan.phar php-cs-fixer.phar; \
    wp --version --allow-root; \
    phpstan --version; \
    php-cs-fixer --version

# SQL language server (not in OMP's built-in defaults).
RUN set -eux; \
    cd /tmp; \
    curl -fsSLo sqls.zip \
        "https://github.com/sqls-server/sqls/releases/download/v${SQLS_VERSION}/sqls-linux-${SQLS_VERSION}.zip"; \
    echo "${SQLS_SHA256}  sqls.zip" | sha256sum -c -; \
    unzip -q sqls.zip -d /usr/local/bin; \
    chmod 0755 /usr/local/bin/sqls; \
    rm -f sqls.zip; \
    sqls -version

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
    /home/dev/.omp/plugins \
    /home/dev/.omp/run \
    /home/dev/.config \
    /home/dev/.config/opencode \
    /home/dev/.local \
    /home/dev/.local/share \
    /home/dev/.local/share/opencode \
    /home/dev/.local/state \
    /home/dev/.local/state/opencode \
    /home/dev/.claude \
    /home/dev/.claude/skills \
    /home/dev/.agents \
    /home/dev/.agents/skills \
    /home/dev/.npm-global \
    /home/dev/.npm-global/bin \
    /home/dev/.qoder

RUN install -d -o dev -g dev -m 0755 \
    /usr/share/omarchy/default/agents/skills

# Development environment
ENV HOME=/home/dev
ENV BUN_INSTALL=/home/dev/.bun
ENV GOPATH=/home/dev/go
ENV GOMODCACHE=/home/dev/go/pkg/mod
ENV NPM_CONFIG_PREFIX=/home/dev/.npm-global

ENV PATH="/home/dev/.bun/bin:/home/dev/.npm-global/bin:/home/dev/.opencode/bin:/home/dev/.local/bin:/home/dev/.cargo/bin:/home/dev/go/bin:/usr/local/go/bin:/usr/local/bin:/usr/bin:/bin"

# Run development tools as unprivileged user
USER dev

# Authenticate HTTPS git pushes through gh using GH_TOKEN from the runtime env.
RUN git config --global "credential.https://github.com.helper" "!gh auth git-credential"

# Install Bun and OMP
RUN curl -fsSL https://bun.com/install | bash -s "bun-v${BUN_VERSION}" \
    && bun install -g "@oh-my-pi/pi-coding-agent@${OMP_VERSION}"

# Install OpenCode and Qoder at the pinned versions
RUN curl -fsSL https://opencode.ai/install | bash -s -- --version "${OPENCODE_VERSION}" --no-modify-path \
    && opencode --version

# The qoder npm dispatcher self-bootstraps into $HOME/.qoder and rewrites the
# shell rc on first run. Run both steps against a throwaway HOME so the image
# keeps /home/dev/.qoder a pure mount target and /home/dev/.profile untouched.
RUN mkdir -p /tmp/qoder-check \
    && HOME=/tmp/qoder-check QODER_CONFIG_DIR=/tmp/qoder-check \
       npm install -g "@qoder-ai/qodercli@${QODER_VERSION}" \
    && HOME=/tmp/qoder-check QODER_CONFIG_DIR=/tmp/qoder-check qoder --version \
    && rm -rf /tmp/qoder-check

# Language servers and linters OMP auto-detects (see its lsp/defaults.json).
# The heavy language toolchains (Java, Kotlin, Scala, Haskell, OCaml, Elixir,
# Erlang, Gleam, Dart, Swift, C#, TLA+, Zig, Odin) are intentionally absent;
# install them on demand if a workspace needs one.
RUN npm install -g \
    bash-language-server \
    typescript \
    typescript-language-server \
    vscode-langservers-extracted \
    yaml-language-server \
    "@tailwindcss/language-server" \
    svelte-language-server \
    "@vue/language-server" \
    "@astrojs/language-server" \
    "@biomejs/biome" \
    prettier \
    eslint \
    intelephense \
    dockerfile-language-server-nodejs \
    graphql-language-service-cli \
    "@prisma/language-server" \
    vim-language-server \
    "@olrtg/emmet-language-server" \
    "@ansible/ansible-language-server" \
    markdownlint-cli2 \
    pyright \
    basedpyright \
    "@taplo/cli"

# PHP_CodeSniffer is not packaged in Debian 13.
RUN composer global require --no-interaction --no-progress squizlabs/php_codesniffer \
    && mkdir -p "$HOME/.local/bin" \
    && PHPCS_BIN="$(composer global config bin-dir --absolute)" \
    && ln -sf "$PHPCS_BIN/phpcs" "$HOME/.local/bin/phpcs" \
    && ln -sf "$PHPCS_BIN/phpcbf" "$HOME/.local/bin/phpcbf" \
    && phpcs --version

# TOML and SQL servers are not in OMP's built-in defaults; register them.
RUN printf '%s\n' \
    '{' \
    '  "taplo": {' \
    '    "command": "taplo",' \
    '    "args": ["lsp", "stdio"],' \
    '    "fileTypes": [".toml"],' \
    '    "rootMarkers": [".git", "Cargo.toml", "pyproject.toml"]' \
    '  },' \
    '  "sqls": {' \
    '    "command": "sqls",' \
    '    "args": ["-stdio"],' \
    '    "fileTypes": [".sql"],' \
    '    "rootMarkers": [".git", ".sqls.yml"]' \
    '  }' \
    '}' > /home/dev/lsp.json

WORKDIR /workspace

CMD ["bash"]


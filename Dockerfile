FROM dunglas/frankenphp:1-php8.4-bookworm

ARG NODE_VERSION=24
ARG TAURI_CLI_VERSION=2

# Dépendances système pour Tauri + WebKit
RUN apt-get update && apt-get install -y \
    curl \
    pkg-config \
    build-essential \
    libwebkit2gtk-4.1-dev \
    libgtk-3-dev \
    libayatana-appindicator3-dev \
    librsvg2-dev \
    patchelf \
    unzip \
    && rm -rf /var/lib/apt/lists/*

# Extensions PHP pour Symfony
RUN install-php-extensions \
    pdo_sqlite \
    intl \
    opcache \
    zip

# Rust
RUN curl --proto '=https' --tlsv1.2 https://sh.rustup.rs -sSf | sh -s -- -y
ENV PATH="/root/.cargo/bin:$PATH"

# Tauri CLI
RUN cargo install tauri-cli --version "^${TAURI_CLI_VERSION}"

# Node.js + pnpm
RUN curl -fsSL https://deb.nodesource.com/setup_${NODE_VERSION}.x | bash - \
    && apt-get install -y nodejs \
    && corepack enable pnpm

# Composer + Symfony CLI
RUN curl -sS https://getcomposer.org/installer | php \
    && mv composer.phar /usr/local/bin/composer

RUN curl -sS https://get.symfony.com/cli/installer | bash \
    && mv /root/.symfony5/bin/symfony /usr/local/bin/symfony

WORKDIR /app

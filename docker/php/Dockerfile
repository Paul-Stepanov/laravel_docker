# === STAGE 1: Base — системные зависимости, PHP-расширения, пользователь ===
FROM php:8.2-fpm AS base

ARG USER=laravel
ARG UID=1000
ARG NODE_VERSION=22

ENV USER=${USER} UID=${UID}

WORKDIR /var/www

# Блок 1: Node.js (независим, часто обновляется)
RUN apt-get update && apt-get install -y --no-install-recommends curl \
    && curl -sSL https://deb.nodesource.com/setup_${NODE_VERSION}.x -o /tmp/nodesource_setup.sh \
    && bash /tmp/nodesource_setup.sh \
    && apt-get install -y --no-install-recommends nodejs \
    && apt-get clean \
    && rm -rf /var/lib/apt/lists/* /tmp/nodesource_setup.sh

# Блок 2: Системные пакеты + PHP-расширения (вместе для минимального размера слоя)
RUN apt-get update && apt-get install -y --no-install-recommends \
    build-essential \
    libonig-dev \
    libzip-dev \
    libpng-dev \
    libjpeg62-turbo-dev \
    libfreetype6-dev \
    locales \
    zip \
    jpegoptim optipng pngquant gifsicle \
    unzip \
    git \
    curl \
    && docker-php-ext-configure gd --with-freetype --with-jpeg \
    && docker-php-ext-install pdo_mysql mbstring zip exif pcntl gd \
    && apt-get clean \
    && rm -rf /var/lib/apt/lists/*

# Блок 3: Пользователь (статично, мгновенно)
RUN useradd -G www-data,root -u ${UID} -m -d /home/${USER} ${USER} \
    && mkdir -p /home/${USER}/.composer \
    && chown -R ${USER}:${USER} /home/${USER}

# Composer
COPY --from=composer:2.8.5 /usr/bin/composer /usr/bin/composer

USER ${USER}

# === STAGE 2: Development (с Xdebug и dev-инструментами) ===
FROM base AS development

USER root

RUN apt-get update && apt-get install -y --no-install-recommends nano mc \
    && pecl install xdebug-3.4.0 \
    && apt-get clean && rm -rf /var/lib/apt/lists/*

USER ${USER}

# === STAGE 3: Production (минимальный образ) ===
FROM base AS production

COPY ./docker/php/php.prod.ini /usr/local/etc/php/conf.d/.user.ini
COPY --chown=${USER}:${USER} ./src ./

RUN php artisan storage:link \
    && chmod -R 775 ./storage ./bootstrap/cache

USER ${USER}
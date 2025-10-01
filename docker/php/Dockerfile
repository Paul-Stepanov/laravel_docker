FROM php:7.2-fpm

WORKDIR /var/www

ARG user
ARG uid
ARG NODE_VERSION

# Установка системных зависимостей
RUN sed -i 's/deb.debian.org/archive.debian.org/g' /etc/apt/sources.list && \
    sed -i 's|security.debian.org/debian-security|archive.debian.org/debian-security|g' /etc/apt/sources.list && \
    sed -i '/buster-updates/d' /etc/apt/sources.list

# Установка системных зависимостей
RUN apt-get update && apt-get install -y \
    build-essential \
    libonig-dev \
    libzip-dev \
    libpng-dev \
    libjpeg62-turbo-dev \
    libfreetype6-dev \
    locales \
    zip \
    jpegoptim optipng pngquant gifsicle \
    vim \
    unzip \
    git \
    curl \
    ca-certificates \
    libpq-dev \
    libicu-dev \
    && rm -rf /var/lib/apt/lists/*

# Установка PHP-расширений
RUN docker-php-ext-install -j$(nproc) \
    pgsql \
    pdo_pgsql \
    pdo_mysql \
    mbstring \
    exif \
    pcntl \
    bcmath \
    gd \
    zip \
    intl

# Redis через pecl
RUN pecl channel-update pecl.php.net && \
    pecl install redis-5.3.7

# Установка Xdebug (совместимая версия для PHP 7.2)
RUN pecl install xdebug-2.9.8 \
    && docker-php-ext-enable xdebug

# Установка composer (совместимая версия для PHP 7.2)
COPY --from=composer:2.2 /usr/bin/composer /usr/bin/composer

# Установка nvm и Node.js
ENV NVM_DIR /usr/local/nvm
RUN mkdir -p $NVM_DIR && \
    curl -o- https://raw.githubusercontent.com/nvm-sh/nvm/v0.39.0/install.sh | bash

# Установка конкретной версии Node.js через nvm и настройка PATH
RUN . $NVM_DIR/nvm.sh && \
    nvm install $NODE_VERSION && \
    nvm use $NODE_VERSION && \
    nvm alias default $NODE_VERSION

# Добавление пути к Node.js в переменную среды PATH
ENV PATH $NVM_DIR/versions/node/v$NODE_VERSION/bin:$PATH

RUN useradd -G www-data,root -u $uid -m -d /home/$user $user

RUN chown -R $user:$user $NVM_DIR

# Добавляем скрипты инициализации nvm в .bashrc вашего пользователя
RUN echo 'export NVM_DIR="/usr/local/nvm"' >> /home/${user}/.bashrc && \
    echo '[ -s "$NVM_DIR/nvm.sh" ] && \. "$NVM_DIR/nvm.sh"' >> /home/${user}/.bashrc

RUN mkdir -p /home/$user/.composer && \
    chown -R $user:$user /home/$user

# Копирование конфигурации
COPY ./docker/php/php.ini /usr/local/etc/php/conf.d/php.ini
COPY ./src/composer*.json .

RUN composer config --no-plugins allow-plugins.kylekatarnls/update-helper true

RUN php -d xdebug.mode=off /usr/bin/composer install --no-interaction --no-scripts --no-autoloader

# Копирование всего приложения
COPY ./src .
COPY ./.env .
COPY ./docker/php/update.sh .

RUN php -d xdebug.mode=off /usr/bin/composer dump-autoload --optimize --no-scripts

RUN php artisan storage:link && \
    chmod +x ./update.sh && \
    chown -R $user:$user /usr/src && \
    chmod -R 775 ./storage ./bootstrap/cache

USER $user
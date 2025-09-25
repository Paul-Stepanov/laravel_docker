FROM php:7.4-fpm

WORKDIR /var/www

ARG user
ARG uid
ARG NODE_VERSION

# Установка системных зависимостей
RUN curl -sL https://deb.nodesource.com/setup_$NODE_VERSION.x | bash - \
    && apt-get update && apt-get install -y \
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
    nodejs

RUN apt-get clean && rm -rf /var/lib/apt/lists/*

# Установка расширений PHP
RUN docker-php-ext-install pdo_mysql mbstring zip exif pcntl
RUN docker-php-ext-configure gd --enable-gd --with-freetype=/usr/include/ --with-jpeg=/usr/include/
RUN docker-php-ext-install gd

# Установка Xdebug
RUN pecl install xdebug-3.1.6 \
    && docker-php-ext-enable xdebug

# Установка composer
COPY --from=composer:2.8.5 /usr/bin/composer /usr/bin/composer

RUN useradd -G www-data,root -u $uid -m -d /home/$user $user

RUN mkdir -p /home/$user/.composer && \
    chown -R $user:$user /home/$user

# Копирование конфигурации
COPY ./docker/php/php.ini /usr/local/etc/php/conf.d/php.ini
COPY ./src/composer*.json .

RUN php -d xdebug.mode=off /usr/bin/composer install --no-scripts --no-interaction --optimize-autoloader

# Копирование всего приложения
COPY ./src .
COPY ./.env .
COPY ./docker/php/update.sh .

RUN php artisan storage:link && \
    chmod +x ./update.sh && \
    chown -R $user:$user /usr/src && \
    chmod -R 775 ./storage ./bootstrap/cache

USER $user
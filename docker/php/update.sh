#!/bin/sh

# Устанавливаем зависимости Composer с отключенным Xdebug
if [ -f "composer.json" ] && [ -f "composer.lock" ]; then
    php -d xdebug.mode=off /usr/bin/composer install --no-scripts --no-interaction --optimize-autoloader
fi

php -d xdebug.mode=off /usr/bin/composer dump-autoload --optimize

# Создаем директорию для кэша npm
mkdir -p /tmp/.npm
export npm_config_cache=/tmp/.npm

# Установка зависимостей npm только при необходимости
if [ -f "package.json" ]; then
    npm install
    npm run prod
fi

# Выполняем команды Artisan, также отключая Xdebug
php -d xdebug.mode=off artisan optimize:clear
php -d xdebug.mode=off artisan down
php -d xdebug.mode=off artisan migrate --force

# only production
# php -d xdebug.mode=off artisan config:cache
# php -d xdebug.mode=off artisan route:cache
# php -d xdebug.mode=off artisan view:cache

php -d xdebug.mode=off artisan up
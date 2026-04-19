# Dockerized Laravel Application

Docker-окружение для развёртывания Laravel-приложений. Включает Nginx, PHP-FPM 8.2, MySQL 8.0 и PhpMyAdmin.

## Структура проекта

```
project/
├── docker/
│   ├── mysql/
│   │   ├── initdb/                # SQL-скрипты инициализации БД
│   │   └── my.cnf                 # Конфигурация MySQL
│   ├── nginx/
│   │   └── default.conf.template  # Шаблон конфигурации Nginx
│   └── php/
│       ├── Dockerfile             # Multi-stage Dockerfile (dev/prod)
│       ├── php.dev.ini            # PHP-настройки для разработки
│       ├── php.prod.ini           # PHP-настройки для production
│       └── update.sh              # Скрипт инициализации приложения
├── logs/
│   ├── nginx/                     # Логи Nginx
│   └── php/                       # Логи PHP
├── src/                           # Исходный код Laravel
├── .env                           # Переменные окружения
└── docker-compose.yml
```

## Требования

- Docker
- Docker Compose

## Быстрый старт

### Существующий проект

1. Клонируйте репозиторий Laravel в директорию `src/`:
   ```bash
   git clone <repository-url> src
   ```

2. Скопируйте `.env.example` в `.env` в корне проекта:
   ```bash
   cp .env.example .env
   ```

3. Запустите контейнеры:
   ```bash
   docker compose up -d
   ```

### Новый проект (установка через Composer)

1. Скопируйте `.env.example` в `.env`:
   ```bash
   cp .env.example .env
   ```

2. Запустите MySQL:
   ```bash
   docker compose up -d db
   ```

3. Установите Laravel в `src/`:
   ```bash
   docker compose run --rm --no-deps php bash -c "composer create-project laravel/laravel /var/www/tmp && cp -a /var/www/tmp/. /var/www/ && rm -rf /var/www/tmp"
   ```

4. Запустите все контейнеры:
   ```bash
   docker compose up -d
   ```

### Результат

После запуска доступны:
- **Веб-приложение**: http://localhost
- **PhpMyAdmin**: http://localhost:8080
- **MySQL**: порт 3306

## Переменные окружения

| Переменная | Описание | По умолчанию |
|---|---|---|
| `DB_PASSWORD` | Пароль MySQL (root и пользователь) | `example` |
| `DB_DATABASE` | Имя базы данных | `app` |
| `DB_USERNAME` | Пользователь MySQL | `laravel` |
| `PHP_IDE_CONFIG_SERVER_NAME` | Имя сервера Xdebug в PhpStorm | `xdebug` |
| `NODE_VERSION` | Версия Node.js | `24` |
| `DOMAIN` | Имя сервера для Nginx | `localhost` |
| `DOMAIN_PROD` | Адрес для проксирования медиафайлов | `example.com` |
| `USER` / `UID` | Пользователь внутри PHP-контейнера | `laravel` / `1000` |

## Сервисы

### Nginx

Образ `nginx:alpine`, порты 80 и 443. Конфигурация генерируется из шаблона с подстановкой `DOMAIN` и `DOMAIN_PROD`.

Медиафайлы (изображения, видео, аудио) сначала ищутся локально. Если файл не найден:
- При заданном `DOMAIN_PROD` — проксируется с боевого сервера и кэшируется на 7 дней
- При пустом `DOMAIN_PROD` — возвращается 404

### PHP

Multi-stage Dockerfile на базе `php:8.2-fpm`:

- **base** — системные пакеты, PHP-расширения (`pdo_mysql`, `mbstring`, `zip`, `exif`, `pcntl`, `gd`), Node.js, Composer 2.8
- **development** — добавляет Xdebug 3.4, `nano`, `mc`
- **production** — копирует исходный код, создаёт `storage:link`, выставляет права

В режиме разработки монтируются `php.dev.ini` с настройками Xdebug (trigger mode, порт 9003). PHP работает от пользователя `laravel` (UID 1000).

### MySQL

Образ `mysql:8.0`, порт 3306. Автоматически создаёт пользователя `DB_USERNAME` и базу `DB_DATABASE`. Данные хранятся в Docker volume `mysqlappdata`. SQL-файлы из `docker/mysql/initdb/` выполняются только при первом создании базы.

### update

Одноразовый контейнер, запускаемый перед `php`. Выполняет скрипт `update.sh`:
- Устанавливает зависимости Composer (с отключённым Xdebug)
- Устанавливает NPM-зависимости и собирает фронтенд (`npm run build`)
- Генерирует `APP_KEY`, если он не задан
- Очищает кэш
- Применяет миграции
- Переводит приложение в maintenance mode и обратно

## Работа с базой данных

Для инициализации БД из дампа — поместите SQL-файлы в `docker/mysql/initdb/`. Они выполнятся только при первом запуске, когда база создаётся с нуля.

Подключение:
```bash
# MySQL CLI
docker compose exec db mysql -u laravel -pexample app

# PhpMyAdmin
# http://localhost:8080
```

## Отладка (Xdebug)

Xdebug работает в trigger mode — запускается только при передаче соответствующего cookie/параметра.

Настройка PhpStorm:
1. Имя сервера в Settings > PHP > Servers должно совпадать с `PHP_IDE_CONFIG_SERVER_NAME` из `.env` (по умолчанию `xdebug`)
2. Порт Xdebug — `9003`
3. Включите "Listen for PHP Debug Connections"

Лог Xdebug записывается в `logs/php/xdebug.log`.

## Типичные команды

```bash
# Запуск / остановка
docker compose up -d
docker compose down

# Полная пересборка (без кэша)
docker compose build --no-cache && docker compose up -d

# Пересборка только PHP-образа
docker compose build php

# Логи
docker compose logs -f [nginx|php|db|update]

# Artisan
docker compose exec php php artisan <command>

# Composer
docker compose exec php composer <command>

# npm
docker compose exec php npm <command>

# PHPUnit
docker compose exec php php artisan test --filter=TestMethodName

# Запуск команд БЕЗ Xdebug (быстрее)
docker compose exec php php -d xdebug.mode=off artisan <command>
```

## Production

Для сборки production-образа измените `target` в `docker-compose.yml` с `development` на `production` для сервисов `php` и `update`, затем пересоберите:

```bash
docker compose build php
docker compose up -d
```

Production-образ копирует исходный код внутрь контейнера (без bind-mount), использует `php.prod.ini` с отключённым отображением ошибок.
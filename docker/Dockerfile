FROM composer:2 AS laravel-build

WORKDIR /app

RUN composer create-project --prefer-dist --no-interaction laravel/laravel .

COPY src/routes/api.php routes/api.php
COPY src/routes/web.php routes/web.php
COPY src/bootstrap/app.php bootstrap/app.php
COPY src/database/migrations/2024_01_01_000000_create_registrations_table.php \
     database/migrations/2024_01_01_000000_create_registrations_table.php
COPY src/resources/views/register.blade.php resources/views/register.blade.php
COPY src/app/Http/Controllers/RegisterController.php \
     app/Http/Controllers/RegisterController.php

RUN composer install --no-dev --no-interaction --prefer-dist --optimize-autoloader && \
    php artisan package:discover --ansi

FROM php:8.4-fpm AS runtime

RUN set -eux; \
    apt-get update && apt-get install -y --no-install-recommends \
        nginx supervisor libpq-dev libzip-dev libonig-dev && \
    docker-php-ext-install -j"$(nproc)" pdo pdo_pgsql pgsql mbstring zip opcache && \
    apt-mark manual nginx supervisor libpq5 libzip5 libonig5 && \
    apt-get purge -y --auto-remove libpq-dev libzip-dev libonig-dev && \
    apt-get clean && rm -rf /var/lib/apt/lists/* /tmp/* /var/tmp/*

WORKDIR /var/www/html

RUN rm -rf /var/www/html/*

COPY --from=laravel-build --chown=www-data:www-data /app /var/www/html
COPY config/nginx/default.conf /etc/nginx/sites-available/default
COPY docker/supervisord.conf /etc/supervisor/conf.d/app.conf
COPY docker/entrypoint.sh /entrypoint.sh

RUN chmod +x /entrypoint.sh && \
    chown -R www-data:www-data /var/www/html && \
    chmod -R 775 /var/www/html/storage /var/www/html/bootstrap/cache

EXPOSE 80

ENTRYPOINT ["/entrypoint.sh"]

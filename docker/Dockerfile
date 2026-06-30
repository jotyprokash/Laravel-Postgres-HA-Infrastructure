FROM php:8.3-fpm AS base

RUN apt-get update && apt-get install -y --no-install-recommends \
    nginx supervisor curl unzip libpq-dev libzip-dev libonig-dev && \
    docker-php-ext-install pdo pdo_pgsql pgsql mbstring zip opcache && \
    apt-get clean && rm -rf /var/lib/apt/lists/*

COPY --from=composer:2 /usr/bin/composer /usr/bin/composer

WORKDIR /var/www/html

RUN composer create-project --prefer-dist laravel/laravel . && \
    chown -R www-data:www-data /var/www/html && \
    chmod -R 755 /var/www/html/storage /var/www/html/bootstrap/cache

COPY config/nginx/default.conf /etc/nginx/sites-available/default
COPY docker/supervisord.conf /etc/supervisor/conf.d/app.conf
COPY docker/entrypoint.sh /entrypoint.sh
RUN chmod +x /entrypoint.sh

COPY src/routes/api.php /var/www/html/routes/api.php
COPY src/routes/web.php /var/www/html/routes/web.php
COPY src/database/migrations/2024_01_01_000000_create_registrations_table.php \
     /var/www/html/database/migrations/2024_01_01_000000_create_registrations_table.php
COPY src/resources/views/register.blade.php /var/www/html/resources/views/register.blade.php
COPY src/app/Http/Controllers/RegisterController.php \
     /var/www/html/app/Http/Controllers/RegisterController.php

RUN chown -R www-data:www-data /var/www/html

EXPOSE 80

ENTRYPOINT ["/entrypoint.sh"]

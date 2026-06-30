#!/bin/bash
set -e

cd /var/www/html

# Generate app key if not set
if [ -z "$APP_KEY" ]; then
    php artisan key:generate --force
fi

# Run migrations
php artisan migrate --force

# Cache config and routes for production performance
php artisan config:cache
php artisan route:cache

exec /usr/bin/supervisord -c /etc/supervisor/conf.d/app.conf

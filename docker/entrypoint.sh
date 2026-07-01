#!/bin/bash
set -euo pipefail

cd /var/www/html

if [ -z "${APP_KEY:-}" ]; then
    export APP_KEY
    APP_KEY="$(php artisan key:generate --show)"
fi

php artisan migrate --force

php artisan config:cache
php artisan route:cache

exec /usr/bin/supervisord -c /etc/supervisor/conf.d/app.conf

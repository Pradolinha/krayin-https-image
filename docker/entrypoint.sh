#!/usr/bin/env bash
set -e

export PATH=/usr/local/sbin:/usr/local/bin:/usr/sbin:/usr/bin:/sbin:/bin

APP_DIR="/var/www/html/laravel-crm"

if [ -d "$APP_DIR" ]; then
  cd "$APP_DIR"

  # Permissões (evita travas de sessão/cache)
  chown -R www-data:www-data storage bootstrap/cache 2>/dev/null || true
  chmod -R 775 storage bootstrap/cache 2>/dev/null || true

  # Reaplica caches com env do runtime
  php artisan optimize:clear 2>/dev/null || true
  php artisan config:cache  2>/dev/null || true
fi

exec "$@"

#!/bin/sh
set -e

cd /var/www/html

if [ -z "$APP_KEY" ]; then
  echo "ERROR: APP_KEY env var is required on Render."
  echo "Generate one locally with: php artisan key:generate --show"
  exit 1
fi

php artisan config:clear
php artisan route:clear
php artisan view:clear

php artisan migrate --force

if [ "$RUN_SEEDERS" = "true" ]; then
  echo "Running database seeders..."
  php artisan db:seed --force
fi

php artisan config:cache
php artisan route:cache

exec php artisan serve --host=0.0.0.0 --port="${PORT:-8000}"

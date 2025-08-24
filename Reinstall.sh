#!/bin/bash

set -e

echo "📦 Reinstalling Pterodactyl Panel..."

cd /var/www/pterodactyl || exit 1

curl -sL https://github.com/pterodactyl/panel/releases/latest/download/panel.tar.gz | tar -xzv --strip-components=1

chmod -R 755 storage/* bootstrap/cache

composer install --no-dev --optimize-autoloader

php artisan migrate --seed --force

php artisan view:clear
php artisan config:clear
php artisan cache:clear

systemctl restart pteroq

echo "✅ Reinstallation complete!"

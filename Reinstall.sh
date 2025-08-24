#!/bin/bash

set -e

echo "📦 Reinstalling Pterodactyl Panel..."

cd /var/www/pterodactyl || exit 1

Pull latest files
curl -sL https://github.com/pterodactyl/panel/releases/latest/download/panel.tar.gz | tar -xzv --strip-components=1

Set permissions
chmod -R 755 storage/* bootstrap/cache

Install dependencies
composer install --no-dev --optimize-autoloader

Run migrations
php artisan migrate --seed --force

Clear caches
php artisan view:clear
php artisan config:clear
php artisan cache:clear

Restart queue
systemctl restart pteroq

echo "✅ Reinstallation complete!"

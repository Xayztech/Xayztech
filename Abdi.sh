#!/bin/bash

echo "[*] Menghapus Blueprint dari Panel Pterodactyl..."

cd /var/www/pterodactyl || exit 1

#Hapus folder blueprint jika ada
rm -rf blueprint
rm -rf public/blueprint
rm -rf resources/scripts/extensions/blueprint
rm -rf resources/views/extensions/blueprint

#Bersihkan cache Laravel
php artisan view:clear
php artisan config:clear
php artisan route:clear
php artisan cache:clear

#Install dependensi
if command -v yarn &> /dev/null; then
    yarn install
    yarn run build:production
else
    npm install --legacy-peer-deps
    npm run build:production
fi

#Restart nginx
systemctl restart nginx

echo "[✓] Blueprint berhasil dihapus dan panel telah dipulihkan!"

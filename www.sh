#!/bin/bash

echo -e "[*] Menghapus Blueprint dari Pterodactyl Panel …"

#Hapus folder blueprint jika ada
rm -rf /var/www/pterodactyl/blueprint

#Bersihkan cache Laravel
cd /var/www/pterodactyl
php artisan view:clear
php artisan config:clear
php artisan route:clear
php artisan cache:clear

#Install dependensi
yarn install --ignore-engines

#Build ulang frontend dengan fix untuk Node v20+
export NODE_OPTIONS=--openssl-legacy-provider
yarn run build:production

echo -e "[✓] Blueprint berhasil dihapus dan panel telah dipulihkan!"

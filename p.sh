#!/bin/bash

echo "[*] Menghapus Blueprint dari Pterodactyl Panel..."

cd /var/www/pterodactyl || { echo "Gagal masuk ke direktori panel."; exit 1; }

#Hapus direktori blueprint dari berbagai lokasi
rm -rf resources/scripts/blueprint
rm -rf resources/views/blueprint
rm -rf public/blueprint
rm -rf node_modules/blueprint
rm -rf blueprint

# Hapus semua module & install ulang
rm -rf node_modules
npm install

#Build ulang panel
npm run build:production

#Clear Laravel cache
php artisan optimize:clear
php artisan view:clear
php artisan cache:clear

#Restart layanan
systemctl restart pteroq
systemctl restart nginx

echo "[✓] Blueprint berhasil dihapus dan panel telah dibersihkan."

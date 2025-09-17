#!/bin/bash

echo -e "[*] Menghapus Blueprint dari Pterodactyl Panel..."

# Hapus direktori blueprint
rm -rf /var/www/pterodactyl/blueprint

# Hapus binary/link CLI blueprint jika ada
if [ -f "/usr/local/bin/blueprint" ]; then
  rm -f /usr/local/bin/blueprint
elif [ -f "/usr/bin/blueprint" ]; then
  rm -f /usr/bin/blueprint
fi

# Hapus folder cache blueprint jika ada
rm -rf ~/.blueprint

echo -e "[✓] Blueprint berhasil dihapus sepenuhnya!"
